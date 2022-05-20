## Русский
### Как пользоваться
1. Сохраните [скрипт](https://raw.githubusercontent.com/DmitryArtyomov/genshin-wishes-import/master/import-wishes.ps1 "скрипт") себе на компьютер (ПКМ по ссылке и `Сохранить ссылку как...`).
2. Перейдите в папку, куда вы сохранили скрипт, нажмите ПКМ по скрипту и выберите `Выполнить с помощью PowerShell`
3. Вставьте значение куки `remember-me` с помощью `Ctrl + V` или ПКМ и `Вставить` и нажмите `Enter`.
4. При следующих запусках повторите только шаг **2**.

### Как получить значение куки `remember-me`
1. Перейдите на сайт https://genshin-wishes.com/login и войдите в свой аккаунт.
2. Нажмите `F12` или `Ctrl + Shift + J`, чтобы открыть Инструменты разработчика.
3. Перейдите на вкладку `Application` (*1*)
4. Откройте слева раздел `Cookies` (*2*) и выберите домен (*3*)
5. Дважды кликните по значению `Value` напротив `remember-me` (*4*)
6. Скопируйте значение в буфер обмена (нажмите `Ctrl + C` или ПКМ и `Копировать`).

![](https://i.imgur.com/HxD10ZX.png)

## English
### How to use
1. Download [script](https://raw.githubusercontent.com/DmitryArtyomov/genshin-wishes-import/master/import-wishes.ps1 "script") to your PC (Right-click the link and choose `Save link as...`).
2. Navigate to the folder where you downloaded the script to, Right-click on the script and choose `Run with PowerShell`.
3. Paste the `remember-me` cookie value using `Ctrl + V` or Right-click and `Paste` and press `Enter`.
4. During the next launches repeat only step **2**.

### How to get `remember-me` cookie value
1. Navigate to the site https://genshin-wishes.com/login and sign in to your account.
2. Press `F12` or `Ctrl + Shift + J` to open Developer Tools.
3. Navigate to `Application` tab (*1*)
4. Open `Cookies` on the left (*2*) and select the domain (*3*)
5. Double-click `Value` of `remember-me` (*4*)
6. Copy the value to clipboard (`Ctrl + C` or Right-click and `Copy`).

![](https://i.imgur.com/HxD10ZX.png)
