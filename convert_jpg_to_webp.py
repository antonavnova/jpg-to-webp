#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Консольный скрипт для пакетной конвертации JPEG в WebP.
Использует библиотеку Pillow.
"""

import os
import sys
import time
import argparse
from pathlib import Path

# ========== НАСТРОЙКИ КАЧЕСТВА (менять здесь) ==========
WEBP_QUALITY = 85          # качество WebP (0-100)
WEBP_METHOD = 4            # метод сжатия (0-6, где 6 - медленно/максимально)
WEBP_LOSSLESS = False      # True - lossless режим (игнорирует quality)
# ========================================================

def resolve_file_path(file_path):
    """Преобразует путь в абсолютный, если он неполный."""
    p = Path(file_path)
    if not p.is_absolute() and not str(p).startswith(('./', '../')):
        # относительный путь без ./ -> ищем в текущей рабочей директории
        return Path.cwd() / p
    return p.resolve()

def get_unique_output_path(output_path):
    """Если файл существует, добавляет суффикс (1), (2) и т.д."""
    if not output_path.exists():
        return output_path
    stem = output_path.stem
    parent = output_path.parent
    ext = output_path.suffix
    counter = 1
    while True:
        new_path = parent / f"{stem}({counter}){ext}"
        if not new_path.exists():
            return new_path
        counter += 1

def convert_one_jpg(input_path_str, verbose=True):
    """Конвертирует один JPEG в WebP. Возвращает (успех, сообщение)."""
    try:
        input_path = resolve_file_path(input_path_str)
        if not input_path.is_file():
            return False, f"Файл не найден: {input_path}"
        
        if input_path.suffix.lower() not in ('.jpg', '.jpeg'):
            return False, f"Не JPEG файл: {input_path}"
        
        from PIL import Image
        
        # Открываем изображение
        img = Image.open(input_path)
        # Конвертируем в RGB (на случай CMYK или RGBA)
        if img.mode in ('RGBA', 'LA', 'P'):
            rgb_img = Image.new('RGB', img.size, (255, 255, 255))
            rgb_img.paste(img, mask=img.split()[-1] if img.mode == 'RGBA' else None)
            img = rgb_img
        elif img.mode != 'RGB':
            img = img.convert('RGB')
        
        # Формируем выходной путь
        output_path = input_path.parent / f"{input_path.stem}.webp"
        output_path = get_unique_output_path(output_path)
        
        # Сохраняем в WebP
        img.save(output_path, 'WEBP', quality=WEBP_QUALITY, method=WEBP_METHOD, lossless=WEBP_LOSSLESS)
        
        if verbose:
            original_size = input_path.stat().st_size / 1024
            new_size = output_path.stat().st_size / 1024
            print(f"✅ {input_path.name} -> {output_path.name} ({original_size:.1f}KB -> {new_size:.1f}KB)")
        return True, str(output_path)
    
    except Exception as e:
        return False, str(e)

def convert_from_list(list_file_path, verbose=True):
    """Конвертирует файлы из списка (каждая строка — путь к JPG)."""
    list_path = resolve_file_path(list_file_path)
    if not list_path.is_file():
        print(f"❌ Файл списка не найден: {list_path}")
        return 0, 0
    
    with open(list_path, 'r', encoding='utf-8') as f:
        paths = [line.strip() for line in f if line.strip() and not line.startswith('#')]
    
    success = 0
    failed = 0
    for p in paths:
        ok, _ = convert_one_jpg(p, verbose=verbose)
        if ok:
            success += 1
        else:
            failed += 1
    return success, failed

def print_help():
    """Выводит справку."""
    help_text = '''
═══════════════════════════════════════════════════════════════
🖼️  JPEG → WebP Конвертер (Python + Pillow)
═══════════════════════════════════════════════════════════════

Использование:
  python convert_jpg_to_webp.py --file "путь/к/файлу.jpg"
  python convert_jpg_to_webp.py --list "путь/к/список.txt"
  python convert_jpg_to_webp.py --help

Аргументы:
  --file <path>    Конвертировать один JPG файл
  --list <path>    Конвертировать файлы из текстового списка
  --help, -h       Показать эту справку

Правила работы с путями:
  • Если путь не абсолютный и не начинается с ./ или ../,
    файл ищется в текущей рабочей директории.
  • Выходной WebP создаётся рядом с исходным JPG.
  • При коллизии имён добавляется суффикс (1), (2)...

Примеры:
  python convert_jpg_to_webp.py --file "photo.jpg"
  python convert_jpg_to_webp.py --file "C:/images/photo.jpg"
  python convert_jpg_to_webp.py --list "./images.txt"

Настройки качества (изменить в скрипте):
  WEBP_QUALITY = 85
  WEBP_METHOD = 4
  WEBP_LOSSLESS = False
═══════════════════════════════════════════════════════════════
'''
    print(help_text)

def main():
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument('--file', type=str, help='Путь к одному JPG файлу')
    parser.add_argument('--list', type=str, help='Путь к файлу со списком JPG')
    parser.add_argument('--help', '-h', action='store_true', help='Показать справку')
    args = parser.parse_args()
    
    if args.help or (not args.file and not args.list):
        print_help()
        sys.exit(0)
    
    start_time = time.time()
    
    if args.file:
        ok, msg = convert_one_jpg(args.file)
        success = 1 if ok else 0
        failed = 0 if ok else 1
    else:  # args.list
        success, failed = convert_from_list(args.list)
    
    elapsed = time.time() - start_time
    total = success + failed
    
    print(f"\n📊 Статистика: успешно {success} / всего {total} файлов")
    print(f"⏱️  Время: {elapsed:.2f} сек")

if __name__ == '__main__':
    try:
        from PIL import Image
    except ImportError:
        print("❌ Ошибка: библиотека Pillow не установлена.")
        print("Установите: pip install pillow")
        sys.exit(1)
    main()