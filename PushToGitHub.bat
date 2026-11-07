@echo off
chcp 65001 >nul
echo =======================================================
echo    LiquidMusic iOS - ارسال پروژه به گیت‌هاب (Push)
echo =======================================================
echo.
set /p REPO_URL="لطفاً آدرس ریپازیتوری گیت‌هاب خود را وارد کنید (مثال: https://github.com/username/LiquidMusic-iOS.git): "

if "%REPO_URL%"=="" (
    echo [خطا] آدرس ریپازیتوری وارد نشد.
    pause
    exit /b
)

echo.
echo در حال تنظیم ریموت گیت‌هاب...
"C:\Users\n.sadeghi\AppData\Local\Programs\Git\cmd\git.exe" remote remove origin 2>nul
"C:\Users\n.sadeghi\AppData\Local\Programs\Git\cmd\git.exe" remote add origin %REPO_URL%

echo در حال ارسال کدها به گیت‌هاب...
"C:\Users\n.sadeghi\AppData\Local\Programs\Git\cmd\git.exe" push -u origin main

if %ERRORLEVEL% equ 0 (
    echo.
    echo =======================================================
    echo [موفقیت] کدهای برنامه با موفقیت به گیت‌هاب ارسال شد!
    echo اکنون در تب Actions ریپازیتوری، بیلد IPA در حال اجراست.
    echo پس از چند دقیقه، فایل LiquidMusic-iOS-IPA آماده دانلود خواهد بود.
    echo =======================================================
) else (
    echo.
    echo [توجه] در صورت درخواست نام کاربری و پسورد، برای پسورد از GitHub Personal Access Token (PAT) استفاده فرمایید.
)

pause
