# LiquidMusic for iOS (Native SwiftUI & Swift Port)

> **LiquidMusic v3.8 - نسخه اختصاصی و بومی iOS**  
> بازسازی کامل، ۱ به ۱ و بدون کوچک‌ترین تغییر یا حذفیات از نسخه اندروید LiquidMusic v3.8 به زبان **Swift** و فریم‌ورک مدرن **SwiftUI** (سازگار با iOS 16 و نسخه‌های مدرن و آینده تا iOS 26/27).

---

## 💎 نمای کلی معماری و دیزاین سیستم (Liquid Glass UI)

تمامی المان‌های بصری، رفتارها، ترنزیشن‌ها و افکت‌های فیزیکی نسخه اندروید که بر پایه رابط کاربری مایع و شیشه‌ای (Liquid Glass) طراحی شده بودند، با دقت میلی‌متری در SwiftUI پیاده‌سازی شده‌اند:

1. **جلوه شیشه‌ای مایع (`LiquidGlassModifier`)**:
   - لایه‌بندی پس‌زمینه محو فشرده (`.ultraThinMaterial` / `UIBlurEffect`)
   - خط حاشیه هایلایت شیشه‌ای (Glass Rim) با گرادیانت سفید و اوپاسیتی دقیق `0.18`
   - سایه محیطی نرم (`color: .black.opacity(0.25)`, شعاع ۱۶)
   - ته‌رنگ شیشه متناسب با تم تاریک (`#000000` / `#161618`) یا روشن (`#FFFFFF` / `#F5F5F7`)

2. **فیزیک فنری تعاملی (`LiquidLensSpringModifier`)**:
   - انیمیشن جهش لمسی لنز مایع با پارامترهای الاستیک: `response: 0.35s`, `dampingFraction: 0.70`, `stiffness: 260`
   - مقیاس‌پذیری نرم هنگام فشار دکمه‌ها و المان‌های تعاملی (`scaleEffect: 0.96` تا `0.98`)

3. **۱۲ تم رنگی دقیق (Hex-Accents)**:
   - آبی اقیانوسی (`#2979FF`)
   - فیروزه‌ای تالابی (`#00E5FF`)
   - ارغوانی نئون (`#D500F9`)
   - بنفش رویایی (`#7C4DFF`)
   - سرخابی داغ (`#FF1744`)
   - رز کلاسیک (`#F50057`)
   - غروب آتشین (`#FF6D00`)
   - کهربایی زرین (`#FFD600`)
   - سبز نعنایی زمردی (`#00E676`)
   - یاقوتی مرواریدی (`#C51162`)
   - شیشه‌ای مایع مینیمال (`#B0BEC5`)
   - مونوکروم سفید خالص (`#FFFFFF`)

4. **۱۵ آیکون قابل تعویض برنامه (Dynamic App Icons)**:
   - پشتیبانی از تمام متغیرهای آیکون لانچر اصلی اندروید (Default, Art, Blue, Glass, Gold, Pink, Purple, Red, Rose, Round, Sunset, White, ...) با هدرهای استاندارد `CFBundleAlternateIcons`.

---

## 🎧 قابلیت‌ها و سرویس‌های مهندسی معکوس‌شده ۱:۱

### ۱. موتور صوتی پیشرفته (`AudioPlayerService`)
- پخش همزمان با **AVPlayer** و مدیریت چرخه حیات رسانه در پس‌زمینه (`AVAudioSessionCategoryPlayback`).
- قابلیت **Crossfade** داینامیک از ۳ تا ۲۰ ثانیه با محو شدن موازی صدای قطعه قبلی و افزایش نرم قطعه بعدی.
- پشتیبانی از حالت `crossfadeManual` (کراس‌فید در تغییر دستی آهنگ) و `crossfadeSkip` (اسکیپ سریع).
- تایمر خواب هوشمند (`SleepTimerMode`) با قابلیت **محو تدریجی صدا** (`fadeOnSleep`) پیش از توقف کامل.
- یکپارچگی کامل با کنترل‌سنتر، لاک‌اسکرین و هندزفری از طریق `MPNowPlayingInfoCenter` و `MPRemoteCommandCenter`.

### ۲. دستیار صوتی آفلاین "Jarvis" (`VoiceAssistantService`)
- تشخیص صدای آفلاین با استفاده از فریم‌ورک‌های استاندارد بدون نیاز به اینترنت.
- پشتیبانی از فراخوانی کلمه بیدارباش ("Hey Jarvis" و "Jarvis").
- پشتیبانی از تمامی ۲۰ فرمان صوتی اصلی:
  - پخش / توقف (`play`, `pause`, `stop`, `resume`)
  - رفتن به قطعه بعدی و قبلی (`next`, `previous`, `skip`, `back`)
  - افزایش و کاهش صدا (`volume up`, `volume down`, `mute`, `unmute`)
  - لایک و حذف از علاقه‌مندی‌ها (`like`, `favorite`, `love`, `dislike`)
  - به‌هم‌ریختن و تکرار (`shuffle`, `repeat`, `loop`)
  - فعال‌سازی تایمر خواب (`sleep timer`)

### ۳. سیستم هوشمند متن ترانه (`LyricsService`)
- موتور متن ترانه چهار لایه:
  1. کش آفلاین محلی در پوشه‌های `lyrics/` و `lyrics_online/`
  2. استخراج مستقیم تگ‌های متنی جاسازی‌شده درون فایل صوتی (ID3 SYLT / USLT)
  3. استعلام آنلاین از سرویس جهانی `LRCLIB` بر اساس عنوان، خواننده، آلبوم و طول قطعه
  4. موتور اختصاصی جستجو و اسکرپ متن آهنگ‌های فارسی از وب‌سایت‌های مرجع (گهر، موزیک‌وب، آپ‌موزیک و ...) با پشتیبانی از LRC همگام‌شده میلی‌ثانیه‌ای (`[mm:ss.xx]`).

### ۴. پایگاه داده و فایل سیستم کتابخانه (`LibraryStore`)
- ساختار داده متمرکز `library.json` برای ذخیره‌سازی:
  - لیست علاقه‌مندی‌ها (`favorites`)
  - پلی‌لیست‌های کاربر (`playlists`)
  - آمار تعداد پخش قطعات (`playCounts`)
  - تاریخچه آخرین آهنگ‌های پخش‌شده (`lastPlayed`)
  - ویرایش‌های کاربر بر روی تگ‌ها و کاورها (`SongOverride`)
- اسکن خودکار موزیک‌های پوشه Documents برنامه و اشتراک فایل iTunes/Finder.
- اسکن مستقیم آهنگ‌های موجود در Apple Music کتابخانه محلی کاربر از طریق فریم‌ورک `MediaPlayer` (`MPMediaQuery`).

### ۵. مدیریت پلی‌لیست و اشتراک‌گذاری آرشیو (`PlaylistArchiveService`)
- پشتیبانی کامل از ورودی و خروجی پلی‌لیست‌ها با فرمت فشرده استاندارد `.zip` حاوی ساختار `playlist.json` و تمام فایل‌های صوتی قطعات.
- حالت‌های کاور پلی‌لیست: حالت ۴ تکه ترکیبی (۴ کاور آهنگ اول)، حالت تک کاور، و کاور اختصاصی انتخابی از گالری.

### ۶. مرورگر داخلی با دانلودر هوشمند (`InAppBrowserView`)
- مرورگر وب مبتنی بر `WKWebView` با رابط کاربری شیشه‌ای و نوار آدرس شناور.
- رهگیری خودکار لینک‌های مدیا و فایل‌های صوتی (`.mp3`, `.m4a`, `.wav`, `.flac`, `.aac`) با دانلود مستقیم و ذخیره در حافظه محلی کتابخانه برنامه.

### ۷. ویجت‌های تعاملی (`LiquidMusicWidgets`)
- ویجت‌های مدرن WidgetKit در سایزهای کوچک، متوسط و صفحه قفل (Lock Screen Circular & Rectangular) با نمایش قطعه در حال پخش، دکمه‌های کنترلی و پیشرفت پخش.

---

## 📁 ساختار پوشه‌های پروژه

```
LiquidMusic-iOS/
├── Package.swift                               # تعریف بسته Swift Package Manager
├── LiquidMusic.xcodeproj/
│   └── project.pbxproj                         # فایل تنظیمات پروژه رسمی Xcode
└── LiquidMusic/
    ├── App/
    │   ├── LiquidMusicApp.swift                # نقطه شروع برنامه و هندلر فایل‌های ورودی
    │   ├── Info.plist                          # مجوزهای پس‌زمینه صوتی، میکروفون، گفتار و مدیا
    │   └── LiquidMusic.entitlements            # تنظیمات امنیتی و App Sandbox
    ├── Assets.xcassets/
    │   ├── Contents.json
    │   └── AppIcon.appiconset/                 # آیکون‌های اصلی استخراج‌شده با کیفیت رتینا
    ├── Models/
    │   ├── Song.swift                          # مدل داده قطعه صوتی
    │   ├── Album.swift                         # مدل داده آلبوم
    │   ├── Artist.swift                        # مدل داده خواننده
    │   ├── Playlist.swift                      # مدل داده پلی‌لیست
    │   ├── Lyrics.swift                        # مدل و پارسر فایل‌های LRC
    │   ├── AppSettings.swift                   # ۱۹ تنظیم کاربری عینا مطابق با APK
    │   ├── LibraryData.swift                   # ساختار ذخیره‌سازی library.json
    │   ├── PlayerState.swift                   # وضعیت جاری پخش
    │   └── Enums.swift                         # تمامی Enumها، تم‌ها و مرتب‌سازی‌ها
    ├── Services/
    │   ├── AudioPlayerService.swift            # موتور پخش، کراس‌فید، تایمر خواب، MPRemoteCommand
    │   ├── LibraryStore.swift                  # مدیریت فایل‌ها، متادیتا و اسکنر کتابخانه
    │   ├── LyricsService.swift                 # دریافت لیریک آفلاین، LRCLIB و اسکرپر فارسی
    │   ├── VoiceAssistantService.swift         # دستیار صوتی آفلاین جارویس (Jarvis)
    │   └── PlaylistArchiveService.swift        # فشرده‌سازی و اکسترکت پلی‌لیست‌های ZIP
    ├── Theme/
    │   └── LiquidTheme.swift                   # دیزاین سیستم مایع، رنگ‌ها، افکت بلور و متریال
    ├── Views/
    │   ├── MainContainerView.swift             # نگهدارنده اصلی تب‌ها و مینی‌پلیر
    │   ├── Components/
    │   │   ├── ArtworkImageView.swift          # نمایش کاور با کش و گرید چهارگانه پلی‌لیست
    │   │   ├── GlassTabBar.swift               # تب‌بار شیشه‌ای شناور ۵ گانه
    │   │   ├── MiniPlayerBar.swift             # مینی‌پلیر کپسولی شناور با ژست‌های سوایپ
    │   │   └── MarqueeText.swift               # متن متحرک برای عنوان‌های طولانی
    │   ├── Songs/
    │   │   ├── SongsView.swift                 # تب اصلی قطعات صوتی
    │   │   ├── SongRowView.swift               # سطر قطعه با منوی عملیاتی و وضعیت پخش
    │   │   └── SortSheetView.swift             # پنجره شیشه‌ای گزینه‌های مرتب‌سازی
    │   ├── Library/
    │   │   ├── LibraryHomeView.swift           # صفحه خانگی کتابخانه و مجموعه‌ها
    │   │   ├── CollectionDetailView.swift      # جزئیات علاقه‌مندی‌ها، اخیرا پخش‌شده، پرپخش‌ترین
    │   │   ├── AlbumsView.swift                # نمای گرید آلبوم‌ها و صفحه جزئیات آلبوم
    │   │   ├── ArtistsView.swift               # نمای لیست خوانندگان و ترانه‌های هر خواننده
    │   │   └── FoldersView.swift               # نمای کاوشگر پوشه‌های حافظه
    │   ├── Playlists/
    │   │   ├── PlaylistsView.swift             # تب پلی‌لیست‌ها و صفحه نمایش محتوای پلی‌لیست
    │   │   ├── PlaylistDialogs.swift           # دیالوگ‌های ساخت و تغییر نام پلی‌لیست
    │   │   └── PlaylistCoverSheet.swift        # تنظیمات کاور پلی‌لیست و انتخاب آهنگ
    │   ├── Search/
    │   │   └── SearchView.swift                # جستجوی آنی در عنوان، خواننده، آلبوم و پوشه
    │   ├── Player/
    │   │   ├── NowPlayingView.swift            # صفحه کامل پخش‌کننده با لیریک هماهنگ
    │   │   ├── QueueAndEqualizer.swift         # صف پخش با جابجایی ترتیبی و اکولایزر ۵ بانده
    │   │   ├── SleepTimerSheets.swift          # شیت انتخاب مدت زمان تایمر خواب و پایان قطعه
    │   │   └── SongActionMenuSheet.swift       # منوی عملیات، ویرایشگر تگ‌ها و ویرایشگر لیریک
    │   ├── Settings/
    │   │   └── SettingsView.swift              # صفحه تنظیمات کامل، تم، رنگ، کراس‌فید و آیکون
    │   └── Browser/
    │       └── InAppBrowserView.swift          # مرورگر درون‌برنامه‌ای با قابلیت دانلود موزیک
    └── Widgets/
        └── LiquidMusicWidgets.swift            # ویجت‌های بومی WidgetKit برای هوم‌اسکرین و لاک‌اسکرین
```

---

## 🚀 راهنمای اجرا و نصب در Xcode

۱. پوشه پروژه `LiquidMusic-iOS` را به مک خود انتقال دهید.
۲. فایل `LiquidMusic.xcodeproj` را در نرم‌افزار **Xcode** باز کنید.
۳. در بخش **Signing & Capabilities** در تارگت `LiquidMusic`، حساب اپل آی‌دی توسعه‌دهنده خود (Personal Team یا Developer Account) را انتخاب کنید.
۴. دستگاه آیفون فیزیکی یا شبیه‌ساز (Simulator) دلخواه خود را انتخاب کنید.
۵. دکمه **Run (⌘ + R)** را فشار دهید تا برنامه بدون خطا کامپایل و نصب شود.
