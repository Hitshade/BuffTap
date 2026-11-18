"""Compare the shipped whitelist with preserved Forever research and fresh tooltips.

This discovers candidates, not live obtainability or permission to auto-add them.
Raw tooltip responses stay outside the addon; only curated facts should ship.
"""
from pathlib import Path
import argparse, collections, concurrent.futures, hashlib, html, json, re, urllib.request
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]


def catalog():
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute((ROOT / 'tests/mock.lua').read_text(encoding='utf-8-sig'))
    ns = lua.table()
    for name in (ROOT / 'addon/BuffTap/BuffTap.toc').read_text().splitlines():
        if name.strip().endswith('.lua'):
            lua.execute((ROOT / 'addon/BuffTap' / name.strip()).read_text(encoding='utf-8-sig'), 'BuffTap', ns)
    result = {}
    for _, family in ns.ConsumableFamilies.items():
        if family['hidden']:
            continue
        for _, item in family['items'].items():
            result[int(item['id'])] = {'family': family['key'], 'name': item['name'], 'useSpell': int(item['useSpell'])}
    separate = {}
    for key in ('WeaponChoices', 'CoatingChoices'):
        for _, choice in ns[key].items():
            for _, pair in choice['items'].items():
                separate[int(pair[1])] = key
    for _, item in ns.CampingItems.items():
        separate[int(item['item'])] = 'Camping'
    # Soulstone upkeep belongs to Helpers, not the food/elixir chooser.
    for item_id in (5232, 16892, 16893, 16895, 16896):
        separate[item_id] = 'Readiness Soulstone helper'
    return result, separate


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--research', type=Path, default=ROOT.parent / 'research/food-camp-audit')
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--refresh', action='store_true')
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    previous_path = args.output / 'audit.json'
    previous = json.loads(previous_path.read_text(encoding='utf-8')) if previous_path.is_file() else {}
    previous_rows = {x['id']: x for x in previous.get('rows', [])}
    current, separate = catalog()
    candidates = {}
    source_hashes = {}
    for filename, kind in [('food-audit.json', 'food'), ('other-consumables-audit.json', 'other'), ('other-food-drink-links.json', 'restoration-only')]:
        path = args.research / filename
        source_hashes[filename] = hashlib.sha256(path.read_bytes()).hexdigest()
        for item in json.loads(path.read_text(encoding='utf-8-sig')):
            item_id = int(item['itemID'])
            row = candidates.setdefault(item_id, {'id': item_id, 'researchKinds': [], 'legacyMappings': []})
            row['researchKinds'].append(kind)
            row['legacyMappings'].append({k: item.get(k) for k in ('useSpell', 'name', 'spellName', 'description', 'auraRefs', 'durationMS', 'category', 'conditions', 'status')})
    for item_id, item in current.items():
        candidates.setdefault(item_id, {'id': item_id, 'researchKinds': [], 'legacyMappings': []})['catalog'] = item
    for item_id, row in candidates.items():
        if item_id in separate:
            row['separateFeature'] = separate[item_id]

    def inspect(row):
        item_id = row['id']
        # Plain restoration-only entries have no maintenance-buff evidence.
        # Preserve them as explicit exclusions rather than inventing a buff.
        refresh = row.get('catalog') or any(k != 'restoration-only' for k in row['researchKinds'])
        cache = args.output / f'item-{item_id}.json'
        url = f'https://nether.wowhead.com/forever/tooltip/item/{item_id}'
        if args.refresh and refresh:
            try:
                request = urllib.request.Request(url, headers={'User-Agent': 'BuffTap-catalog-audit'})
                with urllib.request.urlopen(request, timeout=15) as response:
                    raw = response.read()
                json.loads(raw)
                cache.write_bytes(raw)
            except Exception as exc:
                row['fetchError'] = str(exc)
        evidence = cache if cache.is_file() else next((p for p in [args.research/f'item-{item_id}.json',args.research/f'consumable-{item_id}.json'] if p.is_file()), None)
        if evidence:
            raw = evidence.read_bytes()
            digest = hashlib.sha256(raw).hexdigest()
            prior = previous_rows.get(item_id, {}).get('currentTooltip', {})
            tooltip = json.loads(raw)
            text = html.unescape(re.sub(r'<[^>]*>', ' ', tooltip.get('tooltip', '')))
            row['currentTooltip'] = {
                'fetchedThisRun': evidence == cache and args.refresh and 'fetchError' not in row,
                'freshThisAudit': evidence == cache and ((args.refresh and 'fetchError' not in row) or (prior.get('freshThisAudit') and prior.get('sha256') == digest)),
                'evidenceFile': str(evidence),
                'name': tooltip.get('name'), 'text': re.sub(r'\s+', ' ', text).strip(),
                'spellLinks': [int(v) for v in re.findall(r'/forever/spell=(\d+)', tooltip.get('tooltip', ''))],
                'source': url, 'sha256': digest,
            }
        if row.get('catalog'):
            links = row.get('currentTooltip', {}).get('spellLinks', [])
            row['mappingStatus'] = 'matches saved tooltip evidence' if row['catalog']['useSpell'] in links else 'tooltip evidence gap or mismatch'
        else:
            row['mappingStatus'] = 'separate feature' if row.get('separateFeature') else 'not in maintenance whitelist'
        return row

    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        rows = list(pool.map(inspect, sorted(candidates.values(), key=lambda x: x['id'])))
    report = {'scope': 'Preserved Forever research (originally build 1.60.1.70009) and current curated whitelist; each tooltip labels freshness individually; acquisition unverified',
              'sourceHashes': source_hashes, 'catalogCount': len(current), 'candidateCount': len(rows), 'rows': rows}
    (args.output / 'audit.json').write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding='utf-8')
    print('Catalog:', len(current), 'candidate items:', len(rows), 'tooltips:', sum('currentTooltip' in x for x in rows))
    for row in rows:
        tooltip = row.get('currentTooltip', {})
        if row.get('catalog') and row['mappingStatus'] != 'matches saved tooltip evidence':
            print('MAPPING REVIEW', row['id'], row['catalog']['name'], row['catalog']['useSpell'], tooltip.get('spellLinks'))
        elif not row.get('catalog') and not row.get('separateFeature') and tooltip.get('name'):
            print('OMITTED', row['id'], tooltip['name'], tooltip['text'])


if __name__ == '__main__':
    main()
