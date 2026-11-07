@echo off
chcp 65001 >nul
echo ================================================================
echo    LiquidMusic iOS - ارسال خودکار به ریپازیتوری شما در گیت‌هاب
echo ================================================================
echo.
echo ریپازیتوری مقصد: https://github.com/omidaziziofficial/LiquidMusic.git
echo.
echo در حال آماده‌سازی و ارسال کدها به گیت‌هاب...
echo.

"C:\Users\n.sadeghi\AppData\Local\Programs\Git\cmd\git.exe" remote remove origin 2>nul
"C:\Users\n.sadeghi\AppData\Local\Programs\Git\cmd\git.exe" remote add origin https://github.com/omidaziziofficial/LiquidMusic.git
"C:\Users\n.sadeghi\AppData\Local\Programs\Git\cmd\git.exe" push -u origin main

if %ERRORLEVEL% equ 0 (
    echo.
    echo ================================================================
    echo [موفقیت] تمامی کدهای LiquidMusic با موفقیت به گیت‌هاب ارسال شد!
    echo.
    echo اکنون وارد تب Actions در لینک زیر شوید:
    echo https://github.com/omidaziziofficial/LiquidMusic/actions
    echo.
    echo سرور مکینتاش اپل در حال ساخت فایل LiquidMusic.ipa است!
    echo ================================================================
) else (
    echo.
    echo [راهنما] در صورت درخواست لاگین:
    echo می‌توانید با مرورگر لاگین کنید یا توکن دسترسی (PAT) گیت‌هاب را وارد کنید.
)

pause
