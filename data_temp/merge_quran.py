import json
import os

def load_data(filepath):
    """Loads a text file where each line is 'surah|ayah|text'."""
    data = {}
    if not os.path.exists(filepath):
        print(f"File not found: {filepath}")
        return data
        
    with open(filepath, 'r', encoding='utf-8') as f:
        for line in f:
            parts = line.strip().split('|', 2)
            if len(parts) >= 3:
                surah = int(parts[0])
                ayah = int(parts[1])
                text = parts[2]
                
                if surah not in data:
                    data[surah] = {}
                data[surah][ayah] = text
    return data

def main():
    print("Loading datasets...")
    # Load all datasets
    arabic_data = load_data('data_temp/quran-uthmani.txt')
    latin_data = load_data('data_temp/en.transliteration.txt')
    id_trans_data = load_data('data_temp/id.indonesian.txt')
    en_trans_data = load_data('data_temp/en.sahih.txt')
    
    # We also need surah names and ayah counts. 
    # The existing quran.json has this, so let's extract metadata from it first.
    print("Extracting metadata from existing quran.json...")
    surah_meta = {}
    try:
        with open('assets/quran.json', 'r', encoding='utf-8') as f:
            existing_quran = json.load(f)
            for surah in existing_quran:
                surah_num = surah['surah_number']
                surah_meta[surah_num] = {
                    'surah_name': surah['surah_name'],
                    'total_ayah': surah['total_ayah']
                }
    except Exception as e:
        print(f"Error reading existing quran.json: {e}")
        return

    print("Merging data into new structure...")
    new_quran = []
    
    for surah_num in range(1, 115):
        if surah_num not in surah_meta:
            continue
            
        surah_info = {
            "surah_number": surah_num,
            "surah_name": surah_meta[surah_num]['surah_name'],
            "total_ayah": surah_meta[surah_num]['total_ayah'],
            "ayahs": []
        }
        
        for ayah_num in range(1, surah_meta[surah_num]['total_ayah'] + 1):
            ayah_info = {
                "ayah_number": ayah_num,
                "arabic": arabic_data.get(surah_num, {}).get(ayah_num, ""),
                "latin": latin_data.get(surah_num, {}).get(ayah_num, ""),
                "translation_id": id_trans_data.get(surah_num, {}).get(ayah_num, ""),
                "translation_en": en_trans_data.get(surah_num, {}).get(ayah_num, "")
            }
            surah_info["ayahs"].append(ayah_info)
            
        new_quran.append(surah_info)
        
    print("Writing to assets/quran.json...")
    with open('assets/quran.json', 'w', encoding='utf-8') as f:
        json.dump(new_quran, f, ensure_ascii=False, separators=(',', ':'))
        
    print("Done! File size:", os.path.getsize('assets/quran.json'))

if __name__ == '__main__':
    main()
