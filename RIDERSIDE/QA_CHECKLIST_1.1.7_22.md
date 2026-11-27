# LeSgo Affiliates 1.1.7 (22) — phone test checklist

Gawin sa **totoong iPhone**, build **1.1.7 (22)** mula sa TestFlight.
Markahan ang bawat isa: `[x]` pumasa, `[!]` may error (isulat ang eksaktong mensahe o kumuha ng screenshot).

## 0. Bago magsimula

- [ ] **Na-deploy na ang backend** (chat report/block, stock fix, 3% fee, pickup phone, email logo).
      Kung hindi pa, ang Seksyon 2.4 ay *tiyak* na mag-e-error (404).
- [ ] Naka-install ang **build 22** (TestFlight → LeSgo Affiliates → 1.1.7 (22)).
- [ ] May 2 demo account na **approved at walang bayad**: 1 rider, 1 merchant.
- [ ] May 2 **spare account** (rider at merchant) na puwedeng burahin.
- [ ] May LeSgo customer account para sa test order (**food o goods lang**, hindi LesRide).
- [ ] Naka-on ang **Do Not Disturb**, charge ≥ 50%, naka-allow ang Location at Notifications.

## 1. Pagbukas ng app (rider at merchant)

- [ ] May **LeSgo logo** sa launch (hindi blangkong puti).
- [ ] Bumubukas hanggang login screen nang walang crash.
- [ ] Gumagana ang login (rider account).
- [ ] Gumagana ang logout at login ulit (merchant account).

## 2. Rider

### 2.1 Duty at order
- [ ] I-tap ang **Online**. Walang error.
- [ ] Papasok ang test order mula sa customer app (may notification o lalabas sa listahan).
- [ ] **Tanggapin** ang order. Walang error.
- [ ] Lumalabas ang **mapa** (hindi blangko), may pickup at drop-off.
- [ ] Ang **numero ng tindahan** sa order ay totoo (hindi `+639123456789`). *(kailangan ng backend deploy)*
- [ ] Ma-update ang status: arrived at pickup → picked up → in progress.
- [ ] **Upload ng proof photo** gumagana bago tapusin.
- [ ] **Tapusin** ang delivery. Lumalabas sa Earnings/Wallet.

### 2.2 Wallet
- [ ] **Top-up ₱500**: ang app ay nagpapakita ng fee **₱15.00** at total **₱515.00** (3%).
- [ ] Ang halagang lumalabas sa PayMongo/Xendit checkout ay **₱515**, tugma sa app.
- [ ] Pagkatapos bayaran, tumataas ang balance ng ₱500.

### 2.3 Profile at suporta
- [ ] Support email na lumalabas: **Lesgoclaveria@gmail.com** (kung `support@lesgo.com` pa, server config pa ang luma).
- [ ] Gumagana ang support chat (AI assistant).

### 2.4 Chat report / block *(ito ang hahanapin ni Apple)*
- [ ] Buksan ang chat ng active order.
- [ ] **Long-press ng message → Report message** → pumili ng reason → Submit. May kumpirmasyon.
- [ ] Menu **⋮ → Report customer** → Submit. May kumpirmasyon.
- [ ] Menu **⋮ → Block customer**. Napapalitan ang message box ng "blocked" na estado.
- [ ] Hindi na makapag-send habang naka-block.
- [ ] Menu **⋮ → Unblock**. Makakapag-send ulit.
- [ ] Wala sa menu ang "End conversation".

### 2.5 Delete account
- [ ] **Spare rider account**: Profile → Settings → **Delete account** → i-type ang `DELETE` → kumpirmahin.
- [ ] Naka-logout, at hindi na makakapag-login ang account na iyon.

## 3. Merchant

### 3.1 Menu at stock
- [ ] Magdagdag ng bagong menu item. Lumalabas sa menu.
- [ ] I-edit ang item: ilagay ang **stock = 10**, i-save.
- [ ] **Isara at buksan ulit ang app**, tingnan ang item: **stock pa rin ay 10**. *(kailangan ng backend deploy; dati ay nawawala)*
- [ ] Ilagay ang stock sa 0: nawawala o minamarkahan na sold out ang item.

### 3.2 Book (order mula sa sariling menu)
- [ ] **Burahin muna ang lumang item sa cart (🗑️)**, kung meron.
- [ ] Menu → **Book** → pumili ng item → **ADD ORDER**.
- [ ] Ang presyo sa cart ay **tugma sa menu** (hindi ₱10 kung ₱100 ang presyo).
- [ ] **Pin Delivery Location**: nakikita ang **location button sa kanan**, hindi natatakpan ng card.
- [ ] Lumalabas ang **address** (hindi coordinates lang) at tama ang 📍 emoji.
- [ ] **Checkout** gumagana. **Walang** "menu item is no longer available."

### 3.3 Pagproseso ng order
- [ ] Papasok ang test order ng customer sa **Orders**.
- [ ] **Accept order**. Walang error.
- [ ] I-mark na ready. Walang error.
- [ ] Kapag hindi pa active ang merchant: lalabas ang "Restricted – Payment and Approval Required" (inaasahan, hindi bug).
- [ ] Gumagana ang **Reject order** na may reason.

### 3.4 Iba pa
- [ ] **Sales report** nagbubukas.
- [ ] **LesPay top-up**: ₱500 → fee ₱15, total ₱515 (3%), tugma sa checkout.
- [ ] **Withdrawal** (kung available) hanggang sa kumpirmasyon.

### 3.5 Report / block customer *(bago sa merchant side)*
- [ ] Buksan ang isang order → **⋮ sa kanang taas ng Order Details**.
- [ ] **Report customer** → pumili ng reason → Submit. May kumpirmasyon.
- [ ] **Block customer** → kumpirmahin. Ang menu ay nagiging **Unblock customer**.
- [ ] Sa customer app, ang na-block na customer na susubok mag-order sa tindahan ay makakakuha ng
      **"This store is not accepting orders from your account."**
- [ ] **Unblock customer** → makakapag-order ulit ang customer.
- [ ] Ang **staff account** ay nakakakita ng orders ng tindahan at nakakagamit ng menu na ito. *(kailangan ng backend deploy)*

### 3.6 Delete account
- [ ] **Spare merchant account**: Profile → Settings & Support → **Delete account** → i-type ang `DELETE`.
- [ ] Naka-logout, at hindi na makakapag-login. *(kailangan ng backend deploy)*

## 4. Registration (bagong account)

- [ ] Rider: telepono + OTP, personal info, dokumento, terms. Walang error.
- [ ] Merchant: form, ID at permits, OTP, hanggang sa **PayMongo ₱1,000**.
- [ ] Nasa terms ang zero-tolerance clause para sa abusive content.

## 5. Para sa video ni Apple

Magsimula sa home screen at i-tap ang app. Ipakita: registration, login, order mula accept hanggang tapos,
chat Report/Block/Unblock, merchant Orders at Menu, bayad (PayMongo), at Delete account (rider at merchant, gamit ang **spare** accounts).

## Kapag may error

Isulat o i-screenshot ang: **ano ang pinindot, anong mensahe, anong account, anong oras**. Ibigay sa akin at aayusin.
