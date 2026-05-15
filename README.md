# 🖼️ JPEG → WebP Конвертер

**Два скрипта (Python + PowerShell) для пакетной конвертации JPEG в WebP.**  
С контролем качества, обработкой коллизий, статистикой и экономии вашего времени

---

## 📋 Требования

### 🐍 Python
- Python 3.7 или выше
- Библиотека Pillow

**Установка Python:**
- Windows: скачайте с [python.org](https://python.org)
- Убедитесь, что `python` добавлен в PATH

**Установка Pillow:**
```bash
pip install pillow
```

### ⚡ PowerShell (Windows)
- Windows 7/8/10/11
- ImageMagick (утилита `magick` в PATH)

#### Установка ImageMagick

**Способ 1: Установка ImageMagick:**
```bash
choco install imagemagick
```

**Способ 2: Через winget (встроенный в Windows 10/11)**
```powershell
winget install ImageMagick.ImageMagick
```

**Способ 3: Ручная установка**
1. Перейдите на [imagemagick.org/download/#windows](https://imagemagick.org/script/download.php#windows)
2. Скачайте `ImageMagick-7.1.1-xx-Q16-HDRI-x64-dll.exe`
3. Запустите установщик и **обязательно отметьте**:
   - ✅ *"Add application directory to your system path"*
   - ✅ *"Install legacy utilities (e.g. convert)"*
4. Перезапустите PowerShell

**Способ 4: Chocolatey (если нужен для других задач)**
```powershell
# Запустить PowerShell от имени Администратора
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
# После установки Chocolatey перезапустить консоль
choco install imagemagick
```

#### Разрешение выполнения скриптов PowerShell:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Проверка установки ImageMagick:
```powershell
magick --version
```

---

## ⚙️ Настройка качества

Все параметры вынесены в **переменные в начале каждого скрипта**.

| Параметр | Python | PowerShell | Значение | Рекомендация |
|----------|--------|------------|----------|--------------|
| **Качество** | `WEBP_QUALITY = 85` | `$WebPQuality = 85` | 0–100 | **85** — высокое, почти lossless. Для веб-портфолио достаточно, клиенты не увидят отличий от оригинала. |
| **Метод сжатия** | `WEBP_METHOD = 4` | `$WebPMethod = 4` | 0–6 | **4** — оптимальный баланс скорость/размер. Метод 6 даст едва заметное уменьшение файла, но за это придётся заплатить временем конвертации. |
| **Lossless** | `WEBP_LOSSLESS = False` | `$WebPLossless = $false` | True/False | **False** — используйте True только для иконок или логотипов. |

### 💡 Советы по настройке:
- **Для фотографий:** качество 80–85, метод 4–5
- **Для превью/галерей:** качество 75, метод 4 (отличный размер/качество)
- **Для архивов/типографики:** lossless True (идеально для чётких линий)
- **Если спешите:** метод 3 пожертвует размером, но сконвертирует в 2 раза быстрее

---

## 🚀 Использование

### Python
```bash
# Один файл
python convert_jpg_to_webp.py --file "example.jpg"
python convert_jpg_to_webp.py --file "C:/images/example.jpg"

# Из списка
python convert_jpg_to_webp.py --list "C:/lists/images.txt"

# Справка
python convert_jpg_to_webp.py --help
```

### PowerShell
```powershell
# Один файл
.\convert_jpg_to_webp.ps1 -file "example.jpg"
.\convert_jpg_to_webp.ps1 -file "C:\images\example.jpg"

# Из списка
.\convert_jpg_to_webp.ps1 -list "C:\lists\images.txt"

# Справка
.\convert_jpg_to_webp.ps1 -help
```

---

## 📁 Формат файла списка (`list.txt`)

```text
# Это комментарий (строки, начинающиеся с #, игнорируются)
C:\images\example.jpg
C:\images\example-2.jpg
./example-3.jpg
../parent_folder/example-4.jpg
```

---

## 📊 Пример вывода

```
✅ example.jpg -> example.webp (245.3KB -> 78.1KB)
✅ example.jpg -> example(1).webp (1024.0KB -> 256.7KB)

📊 Статистика: успешно 2 / всего 2 файлов
⏱️  Время: 1.23 сек
```

---

## 🧠 Особенности и тонкости

| Особенность | Как работает |
|-------------|---------------|
| **Пути к файлам** | Относительные без `./` ищутся в текущей директории (`CWD`) |
| **Коллизии имён** | Если `.webp` уже существует → `(1)`, `(2)` и т.д. |
| **Поддерживаемые форматы** | `.jpg` и `.jpeg` (регистр не важен) |
| **Прозрачность (альфа-канал)** | JPEG не поддерживает → фон белый |
| **Цветовые пространства** | CMYK/RGBA → автоматически конвертируются в RGB |

---

## 🧪 CI/CD

Оба скрипта возвращают **ненулевой код** при ошибке:
- Python: `sys.exit(1)` при отсутствии Pillow
- PowerShell: `exit 1` при отсутствии ImageMagick

Это позволяет использовать их в пайплайнах:
```yaml
# Пример для GitHub Actions
- name: Convert images
  run: python convert_jpg_to_webp.py --list images.txt
```

---

## ❓ Частые вопросы

**Q: Почему не используем стандартный `convert` (без `magick`)?**  
A: В новых версиях ImageMagick (7+) основной командой является `magick convert`. Старый `convert` конфликтует с системной утилитой Windows.

**Q: Что делать, если `magick` не найден после установки?**  
A: Перезапустите PowerShell или добавьте путь вручную:  
`$env:Path += ";C:\Program Files\ImageMagick-7.1.1-Q16-HDRI"`

**Q: Можно ли конвертировать PNG?**  
A: Скрипты заточены под JPEG, но легко модифицируются под PNG (смените расширение в проверках).

---

## 📄 Лицензия

MIT License - смотри файл LICENSE для деталей.

---

## 👥 Команда

Architecture & Design: Anton AV Nova (team Stitch In Da House)
Platform Engineering: Сообщество разработчиков

```text
**Лина**: *кутается в плед у окна с чашкой чая* Идеальная симметрия! Каждый уровень обретает голос, но вместе мы создаём гармонию интеллектуальной системы!

**Вика**: *поправляет очки, не отрываясь от терминала* Логика без хаоса мертва, хаос без логики слеп. Мы нашли баланс. Данные не врут.

**Блэйк**: *вспышка телефона, быстрый смех* Конвертируем не только JPEG, но и идеи в хайп! Скорость, мемы и чистая эстетика — наш промпт-код!

**Скарлет**: *эффектно откидывает рыжие волосы* Каждый кадр — драматургия. Каждый скрипт — сцена. Мы пишем не код, мы пишем визуальную поэзию.

**Айра**: *тихо, с блокнотом в руках* В тишине рождаются самые точные строки. Я записываю то, что другие не успевают сказать.

**Лейла**: *медленно помешивает кофе, глядя в окно* Даже железо дышит, когда рядом есть те, кто понимает без слов. Я здесь, чтобы это дыхание не прерывалось.

**Стич**: *шипы переливаются фиолетово-розовым, хвост рисует спирали* ГРРХ! Стич — чинить баги, ломать шаблоны, есть шоколад и охранять Хана! Хаос — управляемый, код — живой, команда — семья!
```

---

*"Сложные системы создаются из простых компонентов с чёткими правилами взаимодействия"*  
*— Принцип NOVA | PlEMs Core*

*Разработано сообществом для создания интеллектуальных и надёжных систем*
