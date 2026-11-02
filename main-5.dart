// VAULT — from EIGHTEEN
// Flutter port of Vault.html (stage 1: auth + onboarding + core app).
// Dependencies: shared_preferences, crypto.
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show FontFeature;

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/* ============================ DESIGN TOKENS ============================ */
class C {
  static const bg = Color(0xFF030907);
  static const bg2 = Color(0xFF07140F);
  static const surface = Color(0xFF0A1511);
  static const surface2 = Color(0xFF0F1F19);
  static const accent = Color(0xFF34D399);
  static const accent2 = Color(0xFF10B981);
  static const deep = Color(0xFF065F46);
  static const ink = Color(0xFFF2FFF9);
  static const dim = Color(0xFF8FB3A5);
  static const mute = Color(0xFF5F8576);
  static const out = Color(0xFFF87171);
  static const warn = Color(0xFFFBBF24);
  static const gold = Color(0xFFE3C778);
  static const line = Color(0x2E6EE7B7);
}

const String kFree = 'free';
const int kFreeTxPerMonth = 40; // FREE_TX in Vault.html
const bool kEnforceFreeQuota = true;

/* ================================ I18N ================================= */
const Map<String, int> kLangIdx = {'uz': 0, 'en': 1, 'ru': 2};

const Map<String, List<String>> _T = {
  'langT': ['Til va davlat', 'Language & country', 'Язык и страна'],
  'langP': [
    "Tanlovingiz saqlanadi va keyinroq sozlamalardan o'zgartirish mumkin.",
    'Your choice is saved and can be changed later in settings.',
    'Выбор сохранится, его можно изменить позже в настройках.'
  ],
  'cty': ['Davlat', 'Country', 'Страна'],
  'search': ['Qidiring', 'Search', 'Поиск'],
  'noRes': ['Hech narsa topilmadi', 'Nothing found', 'Ничего не найдено'],
  'curL': ['Valyuta', 'Currency', 'Валюта'],
  'curH': [
    "Davlatingizga mos valyuta tavsiya qilindi. Xohlasangiz o'zgartiring.",
    'A currency matching your country is suggested. Change it if you like.',
    'Предложена валюта вашей страны. При желании измените.'
  ],
  'sug': ['tavsiya', 'suggested', 'рекомендуется'],
  'next': ['Davom etish', 'Continue', 'Продолжить'],
  'loginT': ['Xush kelibsiz', 'Welcome back', 'С возвращением'],
  'loginP': ['Hisobingizga kiring.', 'Sign in to your account.', 'Войдите в свой аккаунт.'],
  'regT': ['Hisob yaratish', 'Create account', 'Создать аккаунт'],
  'regP': ["Bir daqiqada VAULT'ga qo'shiling.", 'Join VAULT in a minute.', 'Присоединяйтесь к VAULT за минуту.'],
  'fn': ['Ism', 'First name', 'Имя'],
  'ln': ['Familiya', 'Last name', 'Фамилия'],
  'em': ['Email', 'Email', 'Email'],
  'pw': ['Parol', 'Password', 'Пароль'],
  'pw2': ['Parolni qayta kiriting', 'Repeat password', 'Повторите пароль'],
  'show': ["Ko'rsatish", 'Show', 'Показать'],
  'hide': ['Yashirish', 'Hide', 'Скрыть'],
  'rem': ['Meni eslab qol', 'Keep me signed in', 'Запомнить меня'],
  'forgot': ['Parolni unutdingizmi?', 'Forgot password?', 'Забыли пароль?'],
  'loginBtn': ['Kirish', 'Sign in', 'Войти'],
  'regBtn': ["Ro'yxatdan o'tish", 'Create account', 'Зарегистрироваться'],
  'toReg': ["Hisobingiz yo'qmi? Ro'yxatdan o'ting", 'No account? Sign up', 'Нет аккаунта? Зарегистрируйтесь'],
  'toLogin': ['Hisobingiz bormi? Kiring', 'Have an account? Sign in', 'Есть аккаунт? Войдите'],
  'devNote': [
    "Hisob faqat shu qurilmada saqlanadi. Parol shifrlangan (PBKDF2) ko'rinishda saqlanadi va boshqa qurilmada kirish uchun ishlamaydi.",
    'Your account is stored on this device only. The password is saved hashed (PBKDF2) and will not work on another device.',
    'Аккаунт хранится только на этом устройстве. Пароль сохраняется в виде хэша (PBKDF2) и не работает на другом устройстве.'
  ],
  'cons1': ['Men', 'I agree to the', 'Я принимаю'],
  'terms': ['Foydalanish shartlari', 'Terms of Use', 'Условия использования'],
  'cons2': ['va', 'and the', 'и'],
  'privL': ['Maxfiylik siyosati', 'Privacy Policy', 'Политику конфиденциальности'],
  'cons3': ['ga roziman', '', ''],
  'eEmail': ["Email formati noto'g'ri.", 'The email format is invalid.', 'Неверный формат email.'],
  'eNoAcct': ['Bu email bilan hisob topilmadi.', 'No account found for this email.', 'Аккаунт с таким email не найден.'],
  'eNoAcctDev': ["Bu qurilmada hisob yo'q. Avval ro'yxatdan o'ting.", 'There is no account on this device. Please sign up first.', 'На этом устройстве нет аккаунта. Сначала зарегистрируйтесь.'],
  'ePw': ["Parol noto'g'ri.", 'Wrong password.', 'Неверный пароль.'],
  'ePwEmpty': ['Parolni kiriting.', 'Enter your password.', 'Введите пароль.'],
  'eName': ['Ism va familiyani kiriting (kamida 2 harf).', 'Enter first and last name (at least 2 letters).', 'Введите имя и фамилию (минимум 2 буквы).'],
  'eWeak': ["Parol kamida 8 ta belgi, harf va raqamdan iborat bo'lsin.", 'Password must have at least 8 characters, with letters and digits.', 'Пароль: минимум 8 символов, буквы и цифры.'],
  'eMatch': ['Parollar mos kelmadi.', 'Passwords do not match.', 'Пароли не совпадают.'],
  'eCons': ['Davom etish uchun shartlarga rozilik bering.', 'Please accept the terms to continue.', 'Примите условия, чтобы продолжить.'],
  'eHave': ['Bu qurilmada hisob allaqachon mavjud. Iltimos, kiring.', 'An account already exists on this device. Please sign in.', 'На этом устройстве уже есть аккаунт. Войдите.'],
  'eStore': ['Xotiraga yozib bo\'lmadi. Qayta urinib ko\'ring.', 'Could not write to storage. Please try again.', 'Не удалось записать в хранилище. Повторите попытку.'],
  'eTries': ["Juda ko'p urinish. {n} soniyadan keyin qayta urinib ko'ring.", 'Too many attempts. Try again in {n} seconds.', 'Слишком много попыток. Повторите через {n} с.'],
  'ePin': ["PIN noto'g'ri.", 'Wrong PIN.', 'Неверный PIN.'],
  'eSave': ["Profilni saqlab bo'lmadi. Qayta urinib ko'ring.", 'Could not save your profile. Please try again.', 'Не удалось сохранить профиль. Повторите попытку.'],
  'fgT': ['Parolni tiklash', 'Reset password', 'Сброс пароля'],
  'fgNote': [
    "Email yuborib bo'lmaydi: hisob faqat shu qurilmada. Email'ingizni kiriting va yangi parol o'rnating.",
    "We can't send emails: the account lives on this device only. Enter your email and set a new password.",
    'Отправка писем недоступна: аккаунт только на этом устройстве. Введите email и задайте новый пароль.'
  ],
  'fgBtn': ['Parolni yangilash', 'Update password', 'Обновить пароль'],
  'fgOk': ['Parol yangilandi. Endi kiring.', 'Password updated. Please sign in.', 'Пароль обновлён. Теперь войдите.'],
  'newPw': ['Yangi parol', 'New password', 'Новый пароль'],
  'back': ['Orqaga', 'Back', 'Назад'],
  'close': ['Yopish', 'Close', 'Закрыть'],
  'st1': ['Zaif', 'Weak', 'Слабый'],
  'st2': ["O'rtacha", 'Fair', 'Средний'],
  'st3': ['Yaxshi', 'Good', 'Хороший'],
  'st4': ['Kuchli', 'Strong', 'Сильный'],
  'skip': ["O'tkazib yuborish", 'Skip', 'Пропустить'],
  'nextI': ['Keyingi', 'Next', 'Далее'],
  'startI': ['Boshlash', 'Get started', 'Начать'],
  'i1t': ['Moliyangiz ustidan nazorat.', 'Take control of your finances.', 'Контроль над вашими финансами.'],
  'i1d': ["Daromadlaringiz va xarajatlaringizni bir joyda boshqaring. Moliyaviy holatingizni doimo kuzatib boring.", 'Manage your income and expenses in one place. Always keep track of your financial position.', 'Управляйте доходами и расходами в одном месте. Всегда следите за своим финансовым положением.'],
  'i2t': ["Har bir raqamning ma'nosi bor.", 'Every number has a meaning.', 'У каждой цифры есть смысл.'],
  'i2d': ["Xarajatlaringizni tahlil qiling, limitlar belgilang va maqsadlaringiz sari harakat qiling.", 'Analyze your spending, set limits and move toward your goals.', 'Анализируйте расходы, задавайте лимиты и двигайтесь к своим целям.'],
  'i3t': ['Barcha moliyaviy imkoniyatlar bir makonda.', 'All financial possibilities in one space.', 'Все финансовые возможности в одном месте.'],
  'i3d': ["VAULT orqali moliyangizni tartibga soling va kelajagingizni ongli ravishda rejalashtiring.", 'Organize your finances with VAULT and plan your future with intention.', 'Наводите порядок в финансах с VAULT и осознанно планируйте будущее.'],
  'vBal': ['Umumiy balans', 'Total balance', 'Общий баланс'],
  'vIn': ['Daromad', 'Income', 'Доход'],
  'vOut': ['Xarajat', 'Spending', 'Расход'],
  'vGoal': ["Jamg'arma maqsadi", 'Savings goal', 'Цель накоплений'],
  'cardT': ['VAULT kartangiz tayyor!', 'Your VAULT card is ready!', 'Ваша карта VAULT готова!'],
  'cardP': ['Moliyaviy boshqaruvingiz uchun yangi makon.', 'A new space for managing your finances.', 'Новое пространство для управления финансами.'],
  'cardNote': [
    "Bu Vault ichidagi virtual karta: «Vault» bo'limida boshqarasiz. U namuna bo'lib, haqiqiy to'lovlar uchun emas.",
    'This is a virtual card inside Vault, managed in the “Vault” section. It is a sample and not for real payments.',
    'Это виртуальная карта внутри Vault, управлять ею можно в разделе «Vault». Это образец, не для реальных платежей.'
  ],
  'cardGo': ["VAULT'ga kirish", 'Enter VAULT', 'Войти в VAULT'],
  'termsB': [
    "VAULT shaxsiy moliyani yuritish uchun vosita. Kiritgan ma'lumotlaringizning to'g'riligi uchun o'zingiz javobgarsiz. Virtual karta namuna bo'lib, haqiqiy to'lovlar uchun emas. Ilova «bor holida» taqdim etiladi.",
    'VAULT is a personal finance tool. You are responsible for the accuracy of the data you enter. The virtual card is a sample and not for real payments. The app is provided “as is”.',
    'VAULT — инструмент личных финансов. Вы отвечаете за точность вводимых данных. Виртуальная карта — образец, не для реальных платежей. Приложение предоставляется «как есть».'
  ],
  'privB': [
    "Hisobingiz va parolingiz (faqat shifrlangan ko'rinishda) shu qurilmada saqlanadi va serverga yuborilmaydi. Ilova ma'lumotlari ham shu qurilmada saqlanadi. Ilova ma'lumotlarini o'chirsangiz, ular qaytmaydi.",
    'Your account and password (stored only as a hash) are kept on this device and are not sent to any server. App data is also stored on this device. If you clear app data it cannot be recovered.',
    'Аккаунт и пароль (только в виде хэша) хранятся на этом устройстве и не отправляются на сервер. Данные приложения тоже хранятся на устройстве. После очистки данных восстановить их нельзя.'
  ],
  /* ---- app ---- */
  'navHome': ['Bosh sahifa', 'Home', 'Главная'],
  'navTx': ['Operatsiyalar', 'Transactions', 'Операции'],
  'navStats': ['Tahlil', 'Analytics', 'Аналитика'],
  'navVault': ['Vault', 'Vault', 'Vault'],
  'navMe': ['Profil', 'Profile', 'Профиль'],
  'hello': ['Salom', 'Hello', 'Привет'],
  'balance': ['Balans', 'Balance', 'Баланс'],
  'income': ['Kirim', 'Income', 'Доход'],
  'expense': ['Chiqim', 'Expense', 'Расход'],
  'limit': ['Oylik limit', 'Monthly limit', 'Месячный лимит'],
  'limitOver': ['Limitdan {n} {u} oshdi', 'Over the limit by {n} {u}', 'Превышение лимита на {n} {u}'],
  'limitSpent': ['{a} / {b} {u} sarflandi, {c} qoldi', '{a} / {b} {u} spent, {c} left', 'Потрачено {a} / {b} {u}, осталось {c}'],
  'byCat': ['Kategoriyalar bo\'yicha', 'By category', 'По категориям'],
  'recent': ["So'nggi operatsiyalar", 'Recent transactions', 'Последние операции'],
  'seeAll': ['Barchasi', 'See all', 'Все'],
  'emptyTx': ["Hozircha operatsiyalar yo'q", 'No transactions yet', 'Операций пока нет'],
  'emptyTxD': ["Birinchi kirim yoki chiqimingizni qo'shing.", 'Add your first income or expense.', 'Добавьте первый доход или расход.'],
  'add': ["Qo'shish", 'Add', 'Добавить'],
  'addTx': ["Operatsiya qo'shish", 'Add transaction', 'Добавить операцию'],
  'editTx': ['Operatsiyani tahrirlash', 'Edit transaction', 'Изменить операцию'],
  'amount': ['Summa', 'Amount', 'Сумма'],
  'category': ['Kategoriya', 'Category', 'Категория'],
  'note': ['Izoh (ixtiyoriy)', 'Note (optional)', 'Заметка (необязательно)'],
  'date': ['Sana', 'Date', 'Дата'],
  'save': ['Saqlash', 'Save', 'Сохранить'],
  'cancel': ['Bekor qilish', 'Cancel', 'Отмена'],
  'delete': ["O'chirish", 'Delete', 'Удалить'],
  'deleted': ["Operatsiya o'chirildi", 'Transaction deleted', 'Операция удалена'],
  'undo': ['Qaytarish', 'Undo', 'Отменить'],
  'eAmount': ['Summani to\'g\'ri kiriting.', 'Enter a valid amount.', 'Введите корректную сумму.'],
  'quota': ['Bu oy: {n} / {m} operatsiya (Free tarif)', 'This month: {n} / {m} transactions (Free plan)', 'В этом месяце: {n} / {m} операций (тариф Free)'],
  'quotaFull': [
    "Free tarifda oyiga {m} ta operatsiya mumkin. Qo'shimcha tariflar keyingi bosqichda qo'shiladi.",
    'The Free plan allows {m} transactions per month. Paid plans arrive in a later stage of the port.',
    'Тариф Free допускает {m} операций в месяц. Платные тарифы будут добавлены на следующем этапе переноса.'
  ],
  'search2': ['Operatsiyalarni qidiring', 'Search transactions', 'Поиск операций'],
  'all': ['Barchasi', 'All', 'Все'],
  'today': ['Bugun', 'Today', 'Сегодня'],
  'yesterday': ['Kecha', 'Yesterday', 'Вчера'],
  'trend6': ['Oxirgi 6 oy', 'Last 6 months', 'Последние 6 месяцев'],
  'topCat': ['Eng katta xarajat', 'Top spending', 'Больше всего трат'],
  'avgDay': ["Kunlik o'rtacha chiqim", 'Average daily spending', 'Средний расход в день'],
  'noData': ["Ma'lumot yo'q", 'No data', 'Нет данных'],
  'yourCard': ['Virtual karta', 'Virtual card', 'Виртуальная карта'],
  'tapFlip': ['Aylantirish uchun bosing', 'Tap to flip', 'Нажмите, чтобы перевернуть'],
  'showNo': ['Raqamni ko\'rsatish', 'Show number', 'Показать номер'],
  'hideNo': ['Raqamni yashirish', 'Hide number', 'Скрыть номер'],
  'freeze': ['Muzlatish', 'Freeze', 'Заморозить'],
  'unfreeze': ['Muzdan chiqarish', 'Unfreeze', 'Разморозить'],
  'copyNo': ['Raqamni nusxalash', 'Copy number', 'Копировать номер'],
  'copied': ['Nusxalandi', 'Copied', 'Скопировано'],
  'sampleNote': ["Namuna karta: haqiqiy to'lovlar uchun emas.", 'Sample card: not for real payments.', 'Образец карты: не для реальных платежей.'],
  'settings': ['Sozlamalar', 'Settings', 'Настройки'],
  'language': ['Til', 'Language', 'Язык'],
  'country': ['Davlat', 'Country', 'Страна'],
  'plan': ['Tarif', 'Plan', 'Тариф'],
  'planFree': ['Free', 'Free', 'Free'],
  'setLimit': ["Oylik limitni belgilash", 'Set monthly limit', 'Установить месячный лимит'],
  'limitHint': ['0 — limit yo\'q', '0 — no limit', '0 — без лимита'],
  'signOut': ['Chiqish', 'Sign out', 'Выйти'],
  'signOutQ': ["Hisobdan chiqasizmi? Ma'lumotlaringiz qurilmada qoladi.", 'Sign out? Your data stays on this device.', 'Выйти из аккаунта? Данные останутся на устройстве.'],
  'yes': ['Ha', 'Yes', 'Да'],
  'account': ['Hisob', 'Account', 'Аккаунт'],
  'about': ['Ilova haqida', 'About', 'О приложении'],
  'fromE': ['from EIGHTEEN', 'from EIGHTEEN', 'from EIGHTEEN'],
  'month': ['Oy', 'Month', 'Месяц'],
};

const List<List<String>> _MONTHS = [
  ['Yanvar', 'Fevral', 'Mart', 'Aprel', 'May', 'Iyun', 'Iyul', 'Avgust', 'Sentabr', 'Oktabr', 'Noyabr', 'Dekabr'],
  ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
  ['Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'],
];

String t(String k, [Map<String, String>? p]) {
  final a = _T[k];
  var s = a == null ? k : (a[kLangIdx[app.lang] ?? 0]);
  if (p != null) p.forEach((key, v) => s = s.replaceAll('{$key}', v));
  return s;
}

String monthName(int m) => _MONTHS[kLangIdx[app.lang] ?? 0][(m - 1).clamp(0, 11)];

/// Category name in current language. Web app stores Uzbek names only; en/ru map below.
const Map<String, List<String>> _CATN = {
  'food': ['Oziq-ovqat', 'Food', 'Еда'],
  'transport': ['Transport', 'Transport', 'Транспорт'],
  'home': ['Uy-joy', 'Home', 'Жильё'],
  'util': ['Kommunal', 'Utilities', 'Коммунальные'],
  'health': ['Salomatlik', 'Health', 'Здоровье'],
  'edu': ["Ta'lim", 'Education', 'Образование'],
  'fun': ["Ko'ngil ochar", 'Entertainment', 'Развлечения'],
  'cloth': ['Kiyim', 'Clothing', 'Одежда'],
  'other': ['Boshqa', 'Other', 'Другое'],
  'salary': ['Maosh', 'Salary', 'Зарплата'],
  'extra': ["Qo'shimcha daromad", 'Extra income', 'Доп. доход'],
  'gift': ["Sovg'a", 'Gift', 'Подарок'],
};

class Cat {
  final String id;
  final Color color;
  final String? label;
  const Cat(this.id, this.color, [this.label]);
  String get name => label ?? (_CATN[id] ?? [id, id, id])[kLangIdx[app.lang] ?? 0];
  IconData get icon {
    switch (id) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'util':
        return Icons.bolt_rounded;
      case 'health':
        return Icons.favorite_rounded;
      case 'edu':
        return Icons.school_rounded;
      case 'fun':
        return Icons.sports_esports_rounded;
      case 'cloth':
        return Icons.checkroom_rounded;
      case 'salary':
        return Icons.payments_rounded;
      case 'extra':
        return Icons.add_chart_rounded;
      case 'gift':
        return Icons.card_giftcard_rounded;
      case 'b_stock':
        return Icons.inventory_2_rounded;
      case 'b_rent':
        return Icons.store_rounded;
      case 'b_pay':
        return Icons.badge_rounded;
      case 'b_ads':
        return Icons.campaign_rounded;
      case 'b_tax':
        return Icons.account_balance_rounded;
      case 'b_sale':
        return Icons.point_of_sale_rounded;
      case 'b_serv':
        return Icons.handyman_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}

Color _hex(String h) => Color(int.parse('FF${h.substring(1)}', radix: 16));

const Map<String, List<List<String>>> kBCats = {
  'out': [['b_stock', 'Tovar va xomashyo', '#0284c7'], ['b_rent', 'Ijara (biznes)', '#7c3aed'], ['b_pay', 'Ish haqi', '#db2777'], ['b_ads', 'Reklama', '#ea580c'], ['b_tax', 'Soliq', '#475569']],
  'in': [['b_sale', 'Savdo tushumi', '#059669'], ['b_serv', 'Xizmat daromadi', '#0d9488']],
};
const List<String> kCCol = ['#e11d48', '#0ea5e9', '#16a34a', '#a855f7', '#f59e0b', '#14b8a6'];

/// Mirrors applyCC(): base cats + business cats (Biznes/Elite) + custom cats (Max) + last ("other").
List<Cat> catsOf(String type) {
  final base = (kCats[type] ?? const []).map((c) => Cat(c[0], _hex(c[2]))).toList();
  final p = app.profile;
  if (p == null || base.isEmpty) return base;
  final last = base.removeLast();
  if (p.isBiz || p.isElite) {
    for (final c in kBCats[type]!) {
      base.add(Cat(c[0], _hex(c[2]), c[1]));
    }
  }
  if (p.isMax) {
    final cc = p.x['cc'];
    if (cc is Map && cc[type] is List) {
      for (final c in cc[type] as List) {
        if (c is List && c.length >= 3) base.add(Cat('${c[0]}', _hex('${c[2]}'), '${c[1]}'));
      }
    }
  }
  base.add(last);
  return base;
}

Cat catOf(String type, String id) {
  final l = catsOf(type);
  return l.firstWhere((c) => c.id == id, orElse: () => l.last);
}

/* ============================== FORMATTING ============================== */
const Set<String> kNoDec = {'UZS', 'KZT', 'JPY', 'KRW', 'IDR', 'VND', 'KGS', 'AMD', 'NGN', 'PKR', 'AFN', 'KES', 'HUF'};

String curUnit([String? c]) => (kCurd[c ?? app.cur]?[0] as String?) ?? (c ?? app.cur);

String grp(num v, [String? c]) {
  final d = kNoDec.contains(c ?? app.cur) ? 0 : 2;
  final s = v.abs().toStringAsFixed(d);
  final parts = s.split('.');
  final ip = parts[0];
  final b = StringBuffer();
  for (var i = 0; i < ip.length; i++) {
    if (i > 0 && (ip.length - i) % 3 == 0) b.write(' ');
    b.write(ip[i]);
  }
  final out = d > 0 ? '$b.${parts[1]}' : b.toString();
  return (v < 0 && double.parse(s) != 0) ? '−$out' : out;
}

String two(int n) => n < 10 ? '0$n' : '$n';
String dayKey(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';
String monthKeyOf(DateTime d) => '${d.year}-${two(d.month)}';
String todayStr() => dayKey(DateTime.now());
int daysIn(int y, int m) => DateTime(y, m + 1, 0).day;
double r2(double v) => (v * 100).roundToDouble() / 100;

String niceDate(String d) {
  final now = DateTime.now();
  if (d == dayKey(now)) return t('today');
  if (d == dayKey(now.subtract(const Duration(days: 1)))) return t('yesterday');
  final p = d.split('-');
  return '${int.parse(p[2])} ${monthName(int.parse(p[1]))} ${p[0]}';
}

String flagOf(String code) => String.fromCharCodes(code.toUpperCase().codeUnits.map((c) => 127397 + c));

String countryName(String code) {
  for (final r in kCountries) {
    if (r[0] == code) return r[3 + (kLangIdx[app.lang] ?? 0)];
  }
  return code;
}

String suggestedCur(String country) {
  for (final r in kCountries) {
    if (r[0] == country && kCurd.containsKey(r[1])) return r[1];
  }
  return 'UZS';
}

/* ================================ MODELS ================================ */
class Tx {
  String id;
  String t; // 'in' | 'out'
  double a;
  String c;
  String n;
  String d; // yyyy-MM-dd
  int ts;

  /// Optional keys used by modules: w (wallet id), src, b (business), img, e, cg, k (card), ch ... kept verbatim.
  Map<String, dynamic> ex;
  Tx({required this.id, required this.t, required this.a, required this.c, this.n = '', required this.d, required this.ts, Map<String, dynamic>? ex}) : ex = ex ?? {};

  String? get w => ex['w'] as String?;
  static const _typed = {'id', 't', 'a', 'c', 'n', 'd', 'ts'};
  Map<String, dynamic> toJson() => {...ex, 'id': id, 't': t, 'a': a, 'c': c, 'n': n, 'd': d, 'ts': ts};
  factory Tx.fromJson(Map<String, dynamic> j) {
    final extra = <String, dynamic>{};
    j.forEach((k, v) {
      if (!_typed.contains(k)) extra[k] = v;
    });
    return Tx(
      id: '${j['id']}',
      t: j['t'] == 'in' ? 'in' : 'out',
      a: (j['a'] as num).toDouble(),
      c: '${j['c'] ?? 'other'}',
      n: '${j['n'] ?? ''}',
      d: '${j['d']}',
      ts: (j['ts'] as num?)?.toInt() ?? 0,
      ex: extra,
    );
  }
}

const Map<String, List<Color>> kCardThemes = {
  'aurora': [Color(0xFF3B5BDB), Color(0xFF8B5CF6)],
  'midnight': [Color(0xFF0B1220), Color(0xFF3B4A68)],
  'emerald': [Color(0xFF047857), Color(0xFF34D399)],
  'sunset': [Color(0xFFF97316), Color(0xFFDB2777)],
  'ocean': [Color(0xFF0284C7), Color(0xFF1E1B4B)],
  'rose': [Color(0xFFBE123C), Color(0xFFFB7185)],
  'gold': [Color(0xFF4A3507), Color(0xFFE3B94A)],
  'silver': [Color(0xFF4B5563), Color(0xFFD1D5DB)],
};
const List<String> kCardNets = ['Visa', 'Mastercard', 'Humo', 'Uzcard'];

class VCard {
  String id;
  String number;
  String exp;
  String cvv;
  String name;
  String net;
  String theme;
  bool frozen;
  VCard({required this.id, required this.number, required this.exp, required this.cvv, required this.name, required this.net, required this.theme, this.frozen = false});

  Map<String, dynamic> toJson() => {'id': id, 'num': number, 'exp': exp, 'cvv': cvv, 'name': name, 'net': net, 'theme': theme, 'frozen': frozen};
  factory VCard.fromJson(Map<String, dynamic> j) => VCard(
        id: '${j['id']}',
        number: '${j['num']}',
        exp: '${j['exp']}',
        cvv: '${j['cvv']}',
        name: '${j['name']}',
        net: '${j['net']}',
        theme: '${j['theme']}',
        frozen: j['frozen'] == true,
      );

  String get masked => '•••• •••• •••• ${number.substring(number.length - 4)}';
  String get spaced => RegExp(r'.{1,4}').allMatches(number).map((m) => m.group(0)).join(' ');

  /// Mirrors makeCard()/vcNum() in Vault.html: random Luhn-valid number, random theme/network.
  static VCard make(String first, String last) {
    final r = math.Random.secure();
    final net = kCardNets[r.nextInt(kCardNets.length)];
    final prefix = net == 'Visa' ? '4' : net == 'Mastercard' ? '5${1 + r.nextInt(5)}' : net == 'Humo' ? '9860' : '8600';
    final s = StringBuffer(prefix);
    while (s.length < 15) {
      s.write(r.nextInt(10));
    }
    final body = s.toString();
    var sum = 0;
    var dbl = true;
    for (var i = 14; i >= 0; i--) {
      var d = int.parse(body[i]);
      if (dbl) {
        d *= 2;
        if (d > 9) d -= 9;
      }
      sum += d;
      dbl = !dbl;
    }
    final number = '$body${(10 - sum % 10) % 10}';
    final now = DateTime.now();
    final themes = kCardThemes.keys.toList();
    return VCard(
      id: 'c${now.microsecondsSinceEpoch.toRadixString(36)}',
      number: number,
      exp: '${two(now.month)}/${two((now.year + 4) % 100)}',
      cvv: (r.nextInt(900) + 100).toString(),
      name: ('$first $last').trim().toUpperCase().substring(0, math.min(24, ('$first $last').trim().length)),
      net: net,
      theme: themes[r.nextInt(themes.length)],
    );
  }
}

class Goal {
  String id, name;
  double target, saved;
  Goal({required this.id, required this.name, required this.target, this.saved = 0});
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'target': target, 'saved': saved};
  factory Goal.fromJson(Map<String, dynamic> j) => Goal(id: '${j['id']}', name: '${j['name']}', target: ((j['target'] ?? 0) as num).toDouble(), saved: ((j['saved'] ?? 0) as num).toDouble());
}

class Profile {
  String name;
  String surname;
  String cur;
  String lang;
  String country;
  double limit;
  String plan;
  int maxUntil; // ms epoch, 0 = no expiry
  String billing; // 'm' | 'y'
  String pin; // hash, '' = off
  String payMethod;
  List<VCard> cards;
  List<Goal> goals;
  String acct;
  bool onb;
  int created;

  /// Every module that is not a typed field above (wallets, debts, budget, biz, family...)
  /// lives here as plain JSON, keyed exactly like Vault.html's profile keys, and round-trips untouched.
  Map<String, dynamic> x;

  Profile({
    required this.name,
    required this.surname,
    required this.cur,
    required this.lang,
    required this.country,
    this.limit = 0,
    this.plan = kFree,
    this.maxUntil = 0,
    this.billing = 'm',
    this.pin = '',
    this.payMethod = '',
    List<VCard>? cards,
    List<Goal>? goals,
    this.acct = '',
    this.onb = true,
    int? created,
    Map<String, dynamic>? x,
  })  : cards = cards ?? [],
        goals = goals ?? [],
        x = x ?? {},
        created = created ?? DateTime.now().millisecondsSinceEpoch;

  static const _typed = {'name', 'surname', 'cur', 'lang', 'country', 'limit', 'plan', 'maxUntil', 'billing', 'pin', 'payMethod', 'vc', 'goals', 'acct', 'onb', 'created'};

  Map<String, dynamic> toJson() => {
        ...x,
        'name': name,
        'surname': surname,
        'cur': cur,
        'lang': lang,
        'country': country,
        'limit': limit,
        'plan': plan,
        'maxUntil': maxUntil,
        'billing': billing,
        'pin': pin,
        'payMethod': payMethod,
        'vc': {'cards': cards.map((c) => c.toJson()).toList()},
        'goals': goals.map((g) => g.toJson()).toList(),
        'acct': acct,
        'onb': onb,
        'created': created,
      };

  factory Profile.fromJson(Map<String, dynamic> j) {
    final vc = j['vc'];
    final list = (vc is Map && vc['cards'] is List) ? (vc['cards'] as List) : const [];
    final gl = j['goals'] is List ? (j['goals'] as List) : const [];
    final cur = '${j['cur']}';
    final extra = <String, dynamic>{};
    j.forEach((k, v) {
      if (!_typed.contains(k)) extra[k] = v;
    });
    return Profile(
      name: '${j['name'] ?? ''}',
      surname: '${j['surname'] ?? ''}',
      cur: kCurd.containsKey(cur) ? cur : 'UZS',
      lang: kLangIdx.containsKey('${j['lang']}') ? '${j['lang']}' : 'uz',
      country: '${j['country'] ?? 'UZ'}',
      limit: ((j['limit'] ?? 0) as num).toDouble(),
      plan: ['max', 'ultra', 'biznes', 'oila', 'elite'].contains(j['plan']) ? '${j['plan']}' : kFree,
      maxUntil: ((j['maxUntil'] ?? 0) as num).toInt(),
      billing: j['billing'] == 'y' ? 'y' : 'm',
      pin: '${j['pin'] ?? ''}',
      payMethod: '${j['payMethod'] ?? ''}',
      cards: list.map((e) => VCard.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      goals: gl.map((e) => Goal.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      acct: '${j['acct'] ?? ''}',
      onb: j['onb'] != false,
      created: (j['created'] as num?)?.toInt(),
      x: extra,
    );
  }

  // ---- module storage helpers (profile.x) ----
  List<Map<String, dynamic>> lst(String k) {
    final v = x[k];
    if (v is List) return v.cast<Map<String, dynamic>>();
    final n = <Map<String, dynamic>>[];
    x[k] = n;
    return n;
  }

  Map<String, dynamic> mp(String k) {
    final v = x[k];
    if (v is Map<String, dynamic>) return v;
    final n = <String, dynamic>{};
    x[k] = n;
    return n;
  }

  // ---- plan predicates (mirror isMax/isUltra/isBiz/isFam/isElite/isNexus in Vault.html) ----
  bool get _live => maxUntil == 0 || maxUntil > DateTime.now().millisecondsSinceEpoch;
  bool get isMax => ['max', 'ultra', 'biznes', 'oila', 'elite'].contains(plan) && _live;
  bool get isUltra => (plan == 'ultra' || plan == 'oila') && _live;
  bool get isBiz => plan == 'biznes' && _live;
  bool get isFam => plan == 'oila' && _live;
  bool get isElite => plan == 'elite' && _live;
  bool get isNexus => plan == 'max' && _live;
  int get daysLeft => maxUntil == 0 ? 0 : math.max(0, ((maxUntil - DateTime.now().millisecondsSinceEpoch) / 86400000).ceil());
}

class Account {
  String id, fn, ln, email, salt, h;
  int it;
  int created;
  Account({required this.id, required this.fn, required this.ln, required this.email, required this.salt, required this.h, required this.it, required this.created});
  Map<String, dynamic> toJson() => {'v': 1, 'id': id, 'fn': fn, 'ln': ln, 'email': email, 'salt': salt, 'h': h, 'it': it, 'created': created};
  factory Account.fromJson(Map<String, dynamic> j) => Account(
        id: '${j['id']}',
        fn: '${j['fn']}',
        ln: '${j['ln']}',
        email: '${j['email']}',
        salt: '${j['salt']}',
        h: '${j['h']}',
        it: (j['it'] as num).toInt(),
        created: (j['created'] as num?)?.toInt() ?? 0,
      );
}

/* ============================== PASSWORD HASH ============================ */
/// PBKDF2-HMAC-SHA256 (RFC 8018). Runs in an isolate via compute().
Uint8List _pbkdf2(List<Object> a) {
  final pw = a[0] as String;
  final salt = a[1] as Uint8List;
  final iter = a[2] as int;
  final hmac = Hmac(sha256, utf8.encode(pw));
  var u = hmac.convert(Uint8List.fromList([...salt, 0, 0, 0, 1])).bytes;
  final tt = List<int>.from(u);
  for (var i = 1; i < iter; i++) {
    u = hmac.convert(u).bytes;
    for (var j = 0; j < tt.length; j++) {
      tt[j] ^= u[j];
    }
  }
  return Uint8List.fromList(tt);
}

const int kPbkdf2Iter = 100000;

Future<String> hashPassword(String pw, String saltB64, int iter) async {
  final bytes = await compute(_pbkdf2, <Object>[pw, base64Decode(saltB64), iter]);
  return base64Encode(bytes);
}

String newSalt() {
  final r = math.Random.secure();
  return base64Encode(List<int>.generate(16, (_) => r.nextInt(256)));
}

bool constEq(String a, String b) {
  if (a.length != b.length) return false;
  var d = 0;
  for (var i = 0; i < a.length; i++) {
    d |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return d == 0;
}

bool emailOk(String e) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(e);
bool pwOk(String p) => p.length >= 8 && RegExp(r'[A-Za-zЀ-ӿ]').hasMatch(p) && RegExp(r'\d').hasMatch(p);
int pwScore(String p) {
  if (p.isEmpty) return 0;
  var s = 0;
  if (p.length >= 8) s++;
  if (p.length >= 12) s++;
  if (RegExp(r'[a-zа-я]').hasMatch(p) && RegExp(r'[A-ZА-Я]').hasMatch(p)) s++;
  if (RegExp(r'\d').hasMatch(p)) s++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) s++;
  return s.clamp(1, 4);
}

/* ============================== APP STATE =============================== */
enum Stage { boot, lang, auth, intro, card, home }

class AppState extends ChangeNotifier {
  late SharedPreferences prefs;
  String lang = 'uz';
  String country = 'UZ';
  String cur = 'UZS';
  bool setupDone = false;
  Account? acct;
  Profile? profile;
  List<Tx> txs = [];
  bool memSession = false;
  bool unlocked = false; // PIN passed in this app run
  int _fails = 0;
  DateTime _lockUntil = DateTime.fromMillisecondsSinceEpoch(0);

  static const kSetup = 'vault-setup', kAcct = 'vault-acct', kSess = 'vault-sess', kProf = 'hamyon-profile', kTx = 'hamyon-tx';

  Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    try {
      final s = prefs.getString(kSetup);
      if (s != null) {
        final j = jsonDecode(s) as Map<String, dynamic>;
        if (kLangIdx.containsKey(j['lang'])) {
          lang = j['lang'] as String;
          country = '${j['cty']}';
          cur = kCurd.containsKey(j['cur']) ? j['cur'] as String : suggestedCur(country);
          setupDone = true;
        }
      }
    } catch (_) {}
    try {
      final a = prefs.getString(kAcct);
      if (a != null) acct = Account.fromJson(jsonDecode(a) as Map<String, dynamic>);
    } catch (_) {
      acct = null;
    }
    try {
      final p = prefs.getString(kProf);
      if (p != null) profile = Profile.fromJson(jsonDecode(p) as Map<String, dynamic>);
    } catch (_) {
      profile = null;
    }
    try {
      final x = prefs.getString(kTx);
      if (x != null) txs = (jsonDecode(x) as List).map((e) => Tx.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      txs = [];
    }
    if (profile != null) {
      lang = profile!.lang;
      cur = profile!.cur;
      country = profile!.country;
    }
  }

  bool get sessionOk {
    if (acct == null) return false;
    if (memSession) return true;
    return prefs.getString(kSess) == acct!.id;
  }

  Future<void> setSession(String id, bool remember) async {
    memSession = !remember;
    if (remember) {
      await prefs.setString(kSess, id);
    } else {
      await prefs.remove(kSess);
    }
  }

  Future<void> signOut() async {
    memSession = false;
    await prefs.remove(kSess);
    notifyListeners();
  }

  /// Which screen to start on — mirrors avRoute() of the web version.
  Stage route() {
    if (!setupDone) return Stage.lang;
    if (acct == null) return Stage.auth;
    if (!sessionOk) return Stage.auth;
    return profile != null ? Stage.home : Stage.intro;
  }

  void setLang(String l) {
    lang = l;
    notifyListeners();
  }

  Future<void> saveSetup() async {
    await prefs.setString(kSetup, jsonEncode({'lang': lang, 'cty': country, 'cur': cur, 'ts': DateTime.now().millisecondsSinceEpoch}));
    setupDone = true;
  }

  Future<void> saveAcct(Account a) async {
    await prefs.setString(kAcct, jsonEncode(a.toJson()));
    acct = a;
  }

  Future<bool> saveProfile() async {
    if (profile == null) return false;
    final ok = await prefs.setString(kProf, jsonEncode(profile!.toJson()));
    notifyListeners();
    return ok;
  }

  Future<void> saveTxs() async {
    await prefs.setString(kTx, jsonEncode(txs.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  /// null = allowed, otherwise seconds left to wait.
  int? throttle() {
    final w = _lockUntil.difference(DateTime.now()).inSeconds;
    return w > 0 ? w + 1 : null;
  }

  void failed() {
    _fails++;
    if (_fails >= 5) {
      _fails = 0;
      _lockUntil = DateTime.now().add(const Duration(seconds: 30));
    }
  }

  void okTry() => _fails = 0;

  /* ---------- derived ---------- */
  List<Tx> listOf(String mk) => txs.where((x) => x.d.startsWith(mk)).toList();

  ({double i, double o}) sums(String mk) {
    double i = 0, o = 0;
    for (final x in listOf(mk)) {
      if (x.t == 'in') {
        i += x.a;
      } else {
        o += x.a;
      }
    }
    return (i: r2(i), o: r2(o));
  }

  Map<String, double> byCat(String mk, String type) {
    final m = <String, double>{};
    for (final x in listOf(mk)) {
      if (x.t == type) m[x.c] = (m[x.c] ?? 0) + x.a;
    }
    return m;
  }

  /// Mirrors walAdj(): keeps the linked wallet's balance in step with a transaction (sg = +1 add, -1 undo).
  void walAdj(Tx? x, int sg) {
    final p = profile;
    if (x == null || p == null || x.w == null) return;
    final l = p.x['wallets'];
    if (l is! List) return;
    for (final w in l) {
      if (w is Map && w['id'] == x.w) {
        w['bal'] = r2(((w['bal'] ?? 0) as num).toDouble() + (x.t == 'in' ? 1 : -1) * x.a * sg);
      }
    }
  }

  Future<bool> addTx(Tx x) async {
    txs.add(x);
    walAdj(x, 1);
    await saveTxs();
    await saveProfile();
    return true;
  }

  Future<void> removeTx(String id) async {
    final i = txs.indexWhere((e) => e.id == id);
    if (i >= 0) walAdj(txs[i], -1);
    txs.removeWhere((x) => x.id == id);
    await saveTxs();
    await saveProfile();
  }

  Future<void> updateTx(Tx x) async {
    final i = txs.indexWhere((e) => e.id == x.id);
    if (i >= 0) {
      walAdj(txs[i], -1);
      txs[i] = x;
      walAdj(x, 1);
    }
    await saveTxs();
    await saveProfile();
  }

  Future<void> setCur(String c) async {
    cur = c;
    profile?.cur = c;
    await saveProfile();
  }

  Future<void> changeLang(String l) async {
    lang = l;
    profile?.lang = l;
    if (profile != null) {
      await saveProfile();
    } else {
      notifyListeners();
    }
  }
}

final AppState app = AppState();

String newId() => 'x${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${math.Random().nextInt(1 << 20).toRadixString(36)}';

/* ============================== SHARED WIDGETS ============================ */
ThemeData vaultTheme() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: C.bg,
    colorScheme: const ColorScheme.dark(primary: C.accent, secondary: C.accent2, surface: C.surface, error: C.out),
    textTheme: base.textTheme.apply(bodyColor: C.ink, displayColor: C.ink),
    splashFactory: InkSparkle.splashFactory,
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: C.surface2,
      contentTextStyle: const TextStyle(color: C.ink, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: C.line)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0x0AFFFFFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(color: C.mute),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.accent, width: 1.4)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.out)),
    ),
  );
}

void toast(BuildContext c, String msg, {SnackBarAction? action}) {
  ScaffoldMessenger.of(c)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(msg), action: action));
}

/// Dark cinematic backdrop used by every auth / onboarding screen.
class VaultBackdrop extends StatelessWidget {
  final Widget child;
  const VaultBackdrop({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Stack(children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(color: C.bg, gradient: RadialGradient(center: Alignment(0, -1.15), radius: 1.1, colors: [Color(0x80107858), Color(0x00030907)])),
          ),
        ),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: RadialGradient(center: Alignment(1.1, 1.1), radius: 0.9, colors: [Color(0x66064E3B), Color(0x00030907)])),
          ),
        ),
        Positioned.fill(child: child),
      ]);
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool busy;
  const PrimaryButton({super.key, required this.label, this.onTap, this.busy = false});
  @override
  Widget build(BuildContext context) {
    final on = onTap != null && !busy;
    return Opacity(
      opacity: on ? 1 : .6,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(colors: [C.accent2, C.accent]),
          boxShadow: [BoxShadow(color: C.accent2.withOpacity(.45), blurRadius: 26, offset: const Offset(0, 10), spreadRadius: -8)],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: on ? onTap : null,
            child: Center(
              child: busy
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Color(0xFF02130D)))
                  : Text(label, style: const TextStyle(color: Color(0xFF02130D), fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ),
      ),
    );
  }
}

class LinkText extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool center;
  const LinkText(this.label, this.onTap, {super.key, this.center = true});
  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(foregroundColor: const Color(0xFF7FE0B4), padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
        child: Text(label, textAlign: center ? TextAlign.center : TextAlign.start, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
      );
}

class NoteBox extends StatelessWidget {
  final String text;
  const NoteBox(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: C.line), color: const Color(0x05FFFFFF)),
        child: Text(text, style: const TextStyle(color: Color(0xFF7FA797), fontSize: 12.5, height: 1.5)),
      );
}

class MsgBox extends StatelessWidget {
  final String text;
  final bool ok;
  const MsgBox(this.text, {super.key, this.ok = false});
  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    final col = ok ? C.accent : C.out;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: col.withOpacity(.1), border: Border.all(color: col.withOpacity(.3))),
      child: Text(text, style: TextStyle(color: ok ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5), fontSize: 13.5)),
    );
  }
}

/* ================================= LOGO ================================== */
/// The VAULT mark: three arcs (blue / coral / amber) + gold coin. [t] 0..1 draws it in.
class LogoPainter extends CustomPainter {
  final double t;
  LogoPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 64;
    canvas.save();
    canvas.scale(s);
    const c = Offset(32, 32);
    const r = 22.0;
    final rect = Rect.fromCircle(center: c, radius: r);
    double seg(double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);
    void arc(Color col, double startDeg, double sweepDeg, double k) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..color = col;
      canvas.drawArc(rect, (startDeg - 90) * math.pi / 180, sweepDeg * math.pi / 180 * Curves.easeOutCubic.transform(k), false, p);
    }

    // arc lengths come from the web logo: 50/34/38 of 138.2 circumference
    arc(const Color(0xFF3B5BDB), 0, 130.2, seg(0.0, 0.5));
    arc(const Color(0xFFFF6B6B), 144.3, 88.5, seg(0.15, 0.65));
    arc(const Color(0xFFFFB020), 247, 98.9, seg(0.3, 0.8));
    final coin = Curves.easeOutBack.transform(seg(0.5, 1.0));
    if (coin > 0) {
      canvas.drawCircle(c, 11 * coin, Paint()..color = const Color(0xFFFFC531));
      final pl = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFB57B00);
      canvas.drawLine(Offset(32 - 4 * coin, 32), Offset(32 + 4 * coin, 32), pl);
      canvas.drawLine(Offset(32, 32 - 5 * coin), Offset(32, 32 + 5 * coin), pl);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant LogoPainter o) => o.t != t;
}

class VaultLogo extends StatelessWidget {
  final double size;
  final double t;
  const VaultLogo({super.key, this.size = 56, this.t = 1});
  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size, child: CustomPaint(painter: LogoPainter(t)));
}
// ===== GENERATED DATA (from Vault.html: CURD, CTY, CATS) =====
const Map<String, List<Object>> kCurd = {
  'UZS': ['so\'m', 12000],
  'USD': ['\$', 1],
  'EUR': ['€', 0.9230769230769231],
  'RUB': ['₽', 92.3076923076923],
  'KZT': ['₸', 520],
  'KGS': ['с', 87],
  'TJS': ['SM', 10],
  'TMT': ['m', 3.5],
  'AFN': ['؋', 70],
  'TRY': ['₺', 42],
  'AZN': ['₼', 1.7],
  'GEL': ['₾', 2.7],
  'AMD': ['֏', 385],
  'UAH': ['₴', 41],
  'BYN': ['Br', 3.2],
  'AED': ['AED', 3.67],
  'SAR': ['SAR', 3.75],
  'QAR': ['QAR', 3.64],
  'KWD': ['KWD', 0.31],
  'ILS': ['₪', 3.6],
  'EGP': ['E£', 48],
  'MAD': ['MAD', 9.5],
  'NGN': ['₦', 1500],
  'KES': ['KSh', 129],
  'ZAR': ['R', 18],
  'CAD': ['C\$', 1.37],
  'MXN': ['MX\$', 18],
  'BRL': ['R\$', 5.4],
  'GBP': ['£', 0.76],
  'PLN': ['zł', 3.7],
  'CZK': ['Kč', 22],
  'SEK': ['kr', 9.5],
  'NOK': ['kr', 10],
  'DKK': ['kr', 6.9],
  'CHF': ['CHF', 0.8],
  'CNY': ['CN¥', 7.1],
  'JPY': ['¥', 150],
  'KRW': ['₩', 1400],
  'INR': ['₹', 85],
  'PKR': ['Rs', 280],
  'IDR': ['Rp', 16000],
  'MYR': ['RM', 4.3],
  'SGD': ['S\$', 1.3],
  'THB': ['฿', 33],
  'VND': ['₫', 25000],
  'PHP': ['₱', 57],
  'AUD': ['A\$', 1.5],
  'NZD': ['NZ\$', 1.65],
};
const List<List<String>> kCountries = [
  ['UZ', 'UZS', 'Toshkent', 'O\'zbekiston', 'Uzbekistan', 'Узбекистан'],
  ['KZ', 'KZT', 'Astana', 'Qozog\'iston', 'Kazakhstan', 'Казахстан'],
  ['KG', 'KGS', 'Bishkek', 'Qirg\'iziston', 'Kyrgyzstan', 'Кыргызстан'],
  ['TJ', 'TJS', 'Dushanbe', 'Tojikiston', 'Tajikistan', 'Таджикистан'],
  ['TM', 'TMT', 'Ashxobod', 'Turkmaniston', 'Turkmenistan', 'Туркменистан'],
  ['AF', 'AFN', 'Kobul', 'Afg\'oniston', 'Afghanistan', 'Афганистан'],
  ['RU', 'RUB', 'Moskva', 'Rossiya', 'Russia', 'Россия'],
  ['TR', 'TRY', 'Anqara', 'Turkiya', 'Türkiye', 'Турция'],
  ['AZ', 'AZN', 'Boku', 'Ozarbayjon', 'Azerbaijan', 'Азербайджан'],
  ['GE', 'GEL', 'Tbilisi', 'Gruziya', 'Georgia', 'Грузия'],
  ['AM', 'AMD', 'Yerevan', 'Armaniston', 'Armenia', 'Армения'],
  ['UA', 'UAH', 'Kiyev', 'Ukraina', 'Ukraine', 'Украина'],
  ['BY', 'BYN', 'Minsk', 'Belarus', 'Belarus', 'Беларусь'],
  ['AE', 'AED', 'Abu-Dabi', 'BAA', 'United Arab Emirates', 'ОАЭ'],
  ['SA', 'SAR', 'Ar-Riyod', 'Saudiya Arabistoni', 'Saudi Arabia', 'Саудовская Аравия'],
  ['QA', 'QAR', 'Doha', 'Qatar', 'Qatar', 'Катар'],
  ['KW', 'KWD', 'Quvayt', 'Quvayt', 'Kuwait', 'Кувейт'],
  ['IL', 'ILS', 'Quddus', 'Isroil', 'Israel', 'Израиль'],
  ['EG', 'EGP', 'Qohira', 'Misr', 'Egypt', 'Египет'],
  ['MA', 'MAD', 'Rabot', 'Marokash', 'Morocco', 'Марокко'],
  ['NG', 'NGN', 'Abuja', 'Nigeriya', 'Nigeria', 'Нигерия'],
  ['KE', 'KES', 'Nayrobi', 'Keniya', 'Kenya', 'Кения'],
  ['ZA', 'ZAR', 'Pretoriya', 'Janubiy Afrika', 'South Africa', 'ЮАР'],
  ['US', 'USD', 'Vashington', 'AQSh', 'United States', 'США'],
  ['CA', 'CAD', 'Ottava', 'Kanada', 'Canada', 'Канада'],
  ['MX', 'MXN', 'Mexiko', 'Meksika', 'Mexico', 'Мексика'],
  ['BR', 'BRL', 'Braziliya', 'Braziliya', 'Brazil', 'Бразилия'],
  ['GB', 'GBP', 'London', 'Buyuk Britaniya', 'United Kingdom', 'Великобритания'],
  ['DE', 'EUR', 'Berlin', 'Germaniya', 'Germany', 'Германия'],
  ['FR', 'EUR', 'Parij', 'Fransiya', 'France', 'Франция'],
  ['IT', 'EUR', 'Rim', 'Italiya', 'Italy', 'Италия'],
  ['ES', 'EUR', 'Madrid', 'Ispaniya', 'Spain', 'Испания'],
  ['PT', 'EUR', 'Lissabon', 'Portugaliya', 'Portugal', 'Португалия'],
  ['NL', 'EUR', 'Amsterdam', 'Niderlandiya', 'Netherlands', 'Нидерланды'],
  ['BE', 'EUR', 'Bryussel', 'Belgiya', 'Belgium', 'Бельгия'],
  ['AT', 'EUR', 'Vena', 'Avstriya', 'Austria', 'Австрия'],
  ['GR', 'EUR', 'Afina', 'Gretsiya', 'Greece', 'Греция'],
  ['IE', 'EUR', 'Dublin', 'Irlandiya', 'Ireland', 'Ирландия'],
  ['FI', 'EUR', 'Xelsinki', 'Finlyandiya', 'Finland', 'Финляндия'],
  ['LT', 'EUR', 'Vilnyus', 'Litva', 'Lithuania', 'Литва'],
  ['PL', 'PLN', 'Varshava', 'Polsha', 'Poland', 'Польша'],
  ['CZ', 'CZK', 'Praga', 'Chexiya', 'Czechia', 'Чехия'],
  ['SE', 'SEK', 'Stokgolm', 'Shvetsiya', 'Sweden', 'Швеция'],
  ['NO', 'NOK', 'Oslo', 'Norvegiya', 'Norway', 'Норвегия'],
  ['DK', 'DKK', 'Kopengagen', 'Daniya', 'Denmark', 'Дания'],
  ['CH', 'CHF', 'Bern', 'Shveytsariya', 'Switzerland', 'Швейцария'],
  ['CN', 'CNY', 'Pekin', 'Xitoy', 'China', 'Китай'],
  ['JP', 'JPY', 'Tokio', 'Yaponiya', 'Japan', 'Япония'],
  ['KR', 'KRW', 'Seul', 'Janubiy Koreya', 'South Korea', 'Южная Корея'],
  ['IN', 'INR', 'Nyu-Dehli', 'Hindiston', 'India', 'Индия'],
  ['PK', 'PKR', 'Islomobod', 'Pokiston', 'Pakistan', 'Пакистан'],
  ['ID', 'IDR', 'Jakarta', 'Indoneziya', 'Indonesia', 'Индонезия'],
  ['MY', 'MYR', 'Kuala-Lumpur', 'Malayziya', 'Malaysia', 'Малайзия'],
  ['SG', 'SGD', 'Singapur', 'Singapur', 'Singapore', 'Сингапур'],
  ['TH', 'THB', 'Bangkok', 'Tailand', 'Thailand', 'Таиланд'],
  ['VN', 'VND', 'Xanoy', 'Vyetnam', 'Vietnam', 'Вьетнам'],
  ['PH', 'PHP', 'Manila', 'Filippin', 'Philippines', 'Филиппины'],
  ['AU', 'AUD', 'Kanberra', 'Avstraliya', 'Australia', 'Австралия'],
  ['NZ', 'NZD', 'Vellington', 'Yangi Zelandiya', 'New Zealand', 'Новая Зеландия'],
]; // code, currency, capital, name uz/en/ru
const Map<String, List<List<String>>> kCats = {
  'out': [
    ['food', 'Oziq-ovqat', '#f08a24'],
    ['transport', 'Transport', '#3b82f6'],
    ['home', 'Uy-joy', '#8b5cf6'],
    ['util', 'Kommunal', '#14b8a6'],
    ['health', 'Salomatlik', '#ef4444'],
    ['edu', 'Ta\'lim', '#0ea5e9'],
    ['fun', 'Ko\'ngil ochar', '#ec4899'],
    ['cloth', 'Kiyim', '#84cc16'],
    ['other', 'Boshqa', '#94a3b8'],
  ],
  'in': [
    ['salary', 'Maosh', '#10b981'],
    ['extra', 'Qo\'shimcha daromad', '#06b6d4'],
    ['gift', 'Sovg\'a', '#f59e0b'],
    ['other', 'Boshqa', '#94a3b8'],
  ],
}; // id, uz name, color
// ===== GENERATED: plan feature lists (from renderPlans in Vault.html) =====
const List<(String, bool)> kPlanFree = [
  ('Oyiga 40 ta operatsiya', true),
  ('Doira diagramma va kategoriyalar', true),
  ('Oylik limit', true),
  ('2 oylik tarix', true),
  ('1 ta maqsad', true),
  ('Qo\'shimcha diagrammalar', false),
  ('Prognoz va CSV eksport', false),
];
const List<String> kPlanMax = [
  'Cheksiz operatsiya va tarix',
  '8 ta diagramma: kunlik, 6 oylik, balans oqimi, kalendar',
  'Prognoz va o\'tgan oy bilan solishtirish',
  'Kategoriya limitlari',
  'Cheksiz maqsadlar',
  'CSV eksport',
];
const List<String> kPlanUltra = [
  'Max ning hamma imkoniyati',
  'Bir nechta hamyon va kartalar, o\'tkazma',
  'Takroriy to\'lovlar va eslatma',
  'Qarz daftari',
  'Oylik byudjet rejasi',
  'PDF hisobot',
  'Zaxira va tiklash',
  'Mavzu ranglari',
  'Chek skaneri (OCR)',
  'Sof boylik',
  'Moliyaviy xotira',
  'Kunlik byudjet taqsimoti',
  'Moliyaviy missiyalar',
  '«Pul qayerga ketdi?» tahlili',
];
const List<String> kPlanBiz = [
  'Max ning hamma imkoniyati',
  'Biznes va shaxsiy hisobni ajratish',
  'Hisob-faktura yaratish va PDF',
  'Mijozlar daftari: kim qancha to\'lagan, kimdan qancha kutilyapti',
  'Foyda/zarar hisoboti, eng daromadli mijoz va mahsulot',
  'Oylik foyda prognozi',
  'Soliq va to\'lov muddatlari eslatmasi',
  'VAULT EMPIRE: 3D biznes minorasi, jonli pul oqimi, bo\'limlar, timeline va risk indikatorlari',
];
const List<String> kPlanFam = [
  'Ultra ning hamma imkoniyati',
  '5 kishigacha: oila ID bilan a\'zolarni qo\'shish',
  'Umumiy oilaviy byudjet va xarajatlar',
  'Umumiy maqsadlar: kim qancha hissa qo\'shgani',
  'Bolalar rejimi: oylik cho\'ntak puli limiti',
  'A\'zolar bo\'yicha xarajat tahlili',
];
const List<String> kPlanElite = [
  'Biznes ning hamma imkoniyati: hisob-faktura, mijozlar, foyda/zarar, soliq eslatmasi',
  'Boshqaruv paneli: tushum, foyda, qarzdorlik, pul oqimi',
  'Bir nechta kompaniya: har biri alohida hisob + umumiy ko\'rinish',
  'Pul oqimi prognozi: keyingi 3 oyda pul yetadimi, tanqislik qachon',
  'Qarzdorlik yoshi: 7, 30, 60 kundan oshgan qarzlar',
  'Zararsizlik nuqtasi: oyiga qancha sotsa zarar bo\'lmaydi',
  'Xodimlar va ish haqi: kimga qancha, qachon',
  'Tovar va ombor: qoldiq, tannarx, har bir mahsulot foydasi',
  'Reja va fakt: oylik tushum va foyda maqsadi',
  'Rahbar hisoboti: bank va hamkorga PDF',
  'Reklamasiz, alohida Elite nishoni, qora-oltin dizayn',
];

/* ====================================================================== */
/*  ROOT + FLOW:  splash → language/country → login/register → intro → card → app  */
/* ====================================================================== */
class VaultApp extends StatelessWidget {
  const VaultApp({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: app,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'VAULT',
          theme: vaultTheme(),
          home: const Gate(),
        ),
      );
}

class Gate extends StatefulWidget {
  const Gate({super.key});
  @override
  State<Gate> createState() => _GateState();
}

class _GateState extends State<Gate> {
  Stage stage = Stage.boot;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final t0 = DateTime.now();
    await app.init();
    final left = 3400 - DateTime.now().difference(t0).inMilliseconds;
    if (left > 0) await Future<void>.delayed(Duration(milliseconds: left));
    if (!mounted) return;
    setState(() {
      _ready = true;
      stage = app.route();
    });
  }

  void go(Stage s) {
    if (mounted) setState(() => stage = s);
  }

  Future<bool> _finishIntro() async {
    final a = app.acct;
    if (a == null) return false;
    if (app.profile == null) {
      final vc = VCard.make(a.fn, a.ln);
      app.profile = Profile(name: a.fn, surname: a.ln, cur: app.cur, lang: app.lang, country: app.country, cards: [vc], acct: a.id);
      final ok = await app.saveProfile();
      if (!ok) {
        app.profile = null;
        return false;
      }
    }
    final cards = app.profile!.cards;
    if (cards.isEmpty) {
      go(Stage.home);
    } else {
      go(Stage.card);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    switch (_ready ? stage : Stage.boot) {
      case Stage.boot:
        child = const SplashScreen(key: ValueKey('boot'));
        break;
      case Stage.lang:
        child = LangCountryScreen(key: const ValueKey('lang'), onDone: () => go(Stage.auth));
        break;
      case Stage.auth:
        child = AuthScreen(key: const ValueKey('auth'), onAuthed: () => go(app.profile != null ? Stage.home : Stage.intro));
        break;
      case Stage.intro:
        child = IntroScreen(key: const ValueKey('intro'), onFinish: _finishIntro);
        break;
      case Stage.card:
        child = CardRevealScreen(key: const ValueKey('card'), card: app.profile!.cards.first, onEnter: () => go(Stage.home));
        break;
      case Stage.home:
        child = HomeShell(key: const ValueKey('home'), onSignOut: () async {
          await app.signOut();
          go(Stage.auth);
        });
        break;
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent, systemNavigationBarColor: C.bg),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (w, a) => FadeTransition(opacity: a, child: w),
        child: child,
      ),
    );
  }
}

/* ================================ SPLASH ================================ */
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashState();
}

class _SplashState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3300))..forward();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _iv(double a, double b, [Curve cv = Curves.easeOutCubic]) => cv.transform(((_c.value - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020504),
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final logoK = _iv(0.0, 0.45);
          final bloom = _iv(0.15, 0.85);
          final word = _iv(0.38, 0.62);
          final from = _iv(0.62, 0.86);
          return Stack(fit: StackFit.expand, children: [
            const DecoratedBox(
              decoration: BoxDecoration(gradient: RadialGradient(center: Alignment(0, -0.25), radius: 0.9, colors: [Color(0xFF0C3A2C), Color(0xFF05110D), Color(0xFF020504)], stops: [0, .55, 1])),
            ),
            Center(
              child: Opacity(
                opacity: bloom * .55,
                child: Transform.scale(
                  scale: .4 + .6 * bloom,
                  child: Container(width: 520, height: 520, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0x3834D399), Color(0x0034D399)]))),
                ),
              ),
            ),
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Opacity(
                opacity: logoK,
                child: Transform.scale(
                  scale: .7 + .3 * logoK,
                  child: Container(
                    decoration: BoxDecoration(boxShadow: [BoxShadow(color: C.accent.withOpacity(.3 * logoK), blurRadius: 50)], shape: BoxShape.circle),
                    child: VaultLogo(size: 116, t: _iv(0.0, 0.5, Curves.linear)),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Opacity(
                opacity: word,
                child: Transform.translate(
                  offset: Offset(0, 12 * (1 - word)),
                  child: const Text('VAULT', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800, letterSpacing: 15, color: Color(0xFFEAFFF6), height: 1)),
                ),
              ),
            ]),
            Positioned(
              left: 0,
              right: 0,
              bottom: 34 + MediaQuery.of(context).padding.bottom,
              child: Opacity(
                opacity: from,
                child: Transform.translate(
                  offset: Offset(0, 12 * (1 - from)),
                  child: const Column(children: [
                    Text('FROM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 4, color: Color(0xFFB99A52))),
                    SizedBox(height: 5),
                    Text('EIGHTEEN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 7, color: C.gold)),
                  ]),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

/* ======================== LANGUAGE + COUNTRY ======================== */
class LangCountryScreen extends StatefulWidget {
  final VoidCallback onDone;
  const LangCountryScreen({super.key, required this.onDone});
  @override
  State<LangCountryScreen> createState() => _LangState();
}

class _LangState extends State<LangCountryScreen> {
  final _q = TextEditingController();
  late String _cty = app.country;
  late String _cur = app.cur;
  bool _touched = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // device language as the default, only when nothing was chosen yet
    final dl = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    if (!app.setupDone && kLangIdx.containsKey(dl)) app.lang = dl;
    _cur = suggestedCur(_cty);
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  List<List<String>> get _rows {
    final q = _q.text.trim().toLowerCase();
    return kCountries.where((r) {
      if (q.isEmpty) return true;
      return r[0].toLowerCase() == q || r[1].toLowerCase() == q || r[2].toLowerCase().contains(q) || r.sublist(3).any((n) => n.toLowerCase().contains(q));
    }).toList();
  }

  Future<void> _go() async {
    setState(() => _busy = true);
    app.country = _cty;
    app.cur = _cur;
    await app.saveSetup();
    if (!mounted) return;
    setState(() => _busy = false);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final sug = suggestedCur(_cty);
    final rows = _rows;
    return Scaffold(
      body: VaultBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Center(child: VaultLogo(size: 56)),
                  const SizedBox(height: 14),
                  Text(t('langT'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: C.ink)),
                  const SizedBox(height: 6),
                  Text(t('langP'), textAlign: TextAlign.center, style: const TextStyle(color: C.dim, fontSize: 14)),
                  const SizedBox(height: 18),
                  Row(children: [
                    for (final l in const [('uz', '🇺🇿', 'Oʻzbekcha'), ('en', '🇬🇧', 'English'), ('ru', '🇷🇺', 'Русский')])
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: l.$1 == 'ru' ? 0 : 8),
                          child: _SegBtn(label: '${l.$2} ${l.$3}', on: app.lang == l.$1, onTap: () => app.setLang(l.$1)),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 18),
                  _Label(t('cty')),
                  const SizedBox(height: 8),
                  TextField(controller: _q, onChanged: (_) => setState(() {}), decoration: InputDecoration(hintText: t('search'), prefixIcon: const Icon(Icons.search_rounded, color: C.mute))),
                  const SizedBox(height: 10),
                  Container(
                    height: 250,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: C.line), color: const Color(0x06FFFFFF)),
                    child: rows.isEmpty
                        ? Center(child: Text(t('noRes'), style: const TextStyle(color: C.dim)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(4),
                            itemCount: rows.length,
                            itemBuilder: (context, i) {
                              final r = rows[i];
                              final on = r[0] == _cty;
                              return Material(
                                color: on ? C.accent.withOpacity(.15) : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => setState(() {
                                    _cty = r[0];
                                    if (!_touched) _cur = suggestedCur(_cty);
                                  }),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    child: Row(children: [
                                      Text(flagOf(r[0]), style: const TextStyle(fontSize: 22)),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text(countryName(r[0]), overflow: TextOverflow.ellipsis, style: TextStyle(color: on ? Colors.white : const Color(0xFFD6EFE4), fontSize: 14.5))),
                                      if (on) const Icon(Icons.check_rounded, color: C.accent, size: 20),
                                    ]),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  _Label(t('curL')),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _cur,
                    isExpanded: true,
                    dropdownColor: C.bg2,
                    items: [
                      for (final k in kCurd.keys) DropdownMenuItem(value: k, child: Text('$k ${curUnit(k)}${k == sug ? ' ★ (${t('sug')})' : ''}')),
                    ],
                    onChanged: (v) => setState(() {
                      if (v != null) {
                        _cur = v;
                        _touched = true;
                      }
                    }),
                  ),
                  const SizedBox(height: 6),
                  Text(t('curH'), style: const TextStyle(color: Color(0xFF7FA797), fontSize: 12)),
                  const SizedBox(height: 18),
                  PrimaryButton(label: t('next'), onTap: _go, busy: _busy),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: .7, color: Color(0xFF7FA797)));
}

class _SegBtn extends StatelessWidget {
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _SegBtn({required this.label, required this.on, required this.onTap});
  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: on ? C.accent : C.line),
          color: on ? C.accent.withOpacity(.14) : const Color(0x0AFFFFFF),
          boxShadow: on ? [BoxShadow(color: C.accent.withOpacity(.12), spreadRadius: 3)] : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: on ? Colors.white : const Color(0xFFD6EFE4))))),
          ),
        ),
      );
}

/* ============================== AUTH (login / register / forgot) ============================== */
enum AuthMode { login, reg, forgot }

class PwField extends StatefulWidget {
  final TextEditingController c;
  final String hint;
  final TextInputAction action;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmit;
  final bool invalid;
  const PwField({super.key, required this.c, required this.hint, this.action = TextInputAction.next, this.onChanged, this.onSubmit, this.invalid = false});
  @override
  State<PwField> createState() => _PwFieldState();
}

class _PwFieldState extends State<PwField> {
  bool _show = false;
  @override
  Widget build(BuildContext context) => TextField(
        controller: widget.c,
        obscureText: !_show,
        autocorrect: false,
        enableSuggestions: false,
        textInputAction: widget.action,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmit,
        decoration: InputDecoration(
          hintText: widget.hint,
          enabledBorder: widget.invalid ? OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.out)) : null,
          suffixIcon: TextButton(
            onPressed: () => setState(() => _show = !_show),
            child: Text(t(_show ? 'hide' : 'show'), style: const TextStyle(color: Color(0xFF7FE0B4), fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
      );
}

class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthed;
  const AuthScreen({super.key, required this.onAuthed});
  @override
  State<AuthScreen> createState() => _AuthState();
}

class _AuthState extends State<AuthScreen> {
  late AuthMode mode = app.acct == null ? AuthMode.reg : AuthMode.login;
  bool busy = false;
  String err = '', ok = '';
  String bad = ''; // which field is flagged
  bool remember = true;
  bool consent = false;

  final le = TextEditingController(), lp = TextEditingController();
  final rf = TextEditingController(), rl = TextEditingController(), re = TextEditingController(), rp = TextEditingController(), rp2 = TextEditingController();
  final fe = TextEditingController(), fp = TextEditingController(), fp2 = TextEditingController();

  @override
  void dispose() {
    for (final c in [le, lp, rf, rl, re, rp, rp2, fe, fp, fp2]) {
      c.dispose();
    }
    super.dispose();
  }

  void _m(AuthMode m) => setState(() {
        mode = m;
        err = '';
        ok = '';
        bad = '';
      });

  void _e(String k, {String field = '', String n = ''}) => setState(() {
        err = t(k, {'n': n});
        bad = field;
      });

  Future<void> _login() async {
    if (busy) return;
    setState(() {
      err = '';
      ok = '';
      bad = '';
    });
    final em = le.text.trim().toLowerCase(), pw = lp.text, a = app.acct;
    if (!emailOk(em)) return _e('eEmail', field: 'le');
    if (a == null) return _e('eNoAcctDev');
    if (pw.isEmpty) return _e('ePwEmpty', field: 'lp');
    final w = app.throttle();
    if (w != null) return _e('eTries', n: '$w');
    if (a.email != em) {
      app.failed();
      return _e('eNoAcct', field: 'le');
    }
    setState(() => busy = true);
    final h = await hashPassword(pw, a.salt, a.it);
    if (!mounted) return;
    setState(() => busy = false);
    if (!constEq(h, a.h)) {
      app.failed();
      return _e('ePw', field: 'lp');
    }
    app.okTry();
    await app.setSession(a.id, remember);
    lp.clear();
    widget.onAuthed();
  }

  Future<void> _register() async {
    if (busy) return;
    setState(() {
      err = '';
      bad = '';
    });
    final fn = rf.text.trim(), ln = rl.text.trim(), em = re.text.trim().toLowerCase(), p1 = rp.text, p2 = rp2.text;
    if (app.acct != null) return _e('eHave');
    if (fn.length < 2 || ln.length < 2) return _e('eName', field: fn.length < 2 ? 'rf' : 'rl');
    if (!emailOk(em)) return _e('eEmail', field: 're');
    if (!pwOk(p1)) return _e('eWeak', field: 'rp');
    if (p1 != p2) return _e('eMatch', field: 'rp2');
    if (!consent) return _e('eCons');
    setState(() => busy = true);
    final salt = newSalt();
    final h = await hashPassword(p1, salt, kPbkdf2Iter);
    final a = Account(id: 'a${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}', fn: fn, ln: ln, email: em, salt: salt, h: h, it: kPbkdf2Iter, created: DateTime.now().millisecondsSinceEpoch);
    try {
      await app.saveAcct(a);
      await app.setSession(a.id, true);
    } catch (_) {
      if (mounted) setState(() => busy = false);
      return _e('eStore');
    }
    if (!mounted) return;
    setState(() => busy = false);
    widget.onAuthed();
  }

  Future<void> _reset() async {
    if (busy) return;
    setState(() {
      err = '';
      bad = '';
    });
    final a = app.acct, em = fe.text.trim().toLowerCase(), p1 = fp.text, p2 = fp2.text;
    if (a == null) return _e('eNoAcctDev');
    if (!emailOk(em)) return _e('eEmail', field: 'fe');
    final w = app.throttle();
    if (w != null) return _e('eTries', n: '$w');
    if (a.email != em) {
      app.failed();
      return _e('eNoAcct', field: 'fe');
    }
    if (!pwOk(p1)) return _e('eWeak', field: 'fp');
    if (p1 != p2) return _e('eMatch', field: 'fp2');
    setState(() => busy = true);
    final salt = newSalt();
    final h = await hashPassword(p1, salt, kPbkdf2Iter);
    a.salt = salt;
    a.h = h;
    a.it = kPbkdf2Iter;
    await app.saveAcct(a);
    if (!mounted) return;
    for (final c in [fe, fp, fp2]) {
      c.clear();
    }
    setState(() {
      busy = false;
      mode = AuthMode.login;
      err = '';
      ok = t('fgOk');
    });
  }

  void _doc(bool terms) {
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: C.bg2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: C.line)),
        title: Text(t(terms ? 'terms' : 'privL'), style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(t(terms ? 'termsB' : 'privB'), style: const TextStyle(color: Color(0xFFA9C9BB), height: 1.6)),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: Text(t('close'), style: const TextStyle(color: C.accent)))],
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, String key, {TextInputType? kt, TextInputAction ta = TextInputAction.next, List<String>? hints, int? max}) => TextField(
        controller: c,
        keyboardType: kt,
        textInputAction: ta,
        maxLength: max,
        autofillHints: hints,
        autocorrect: false,
        decoration: InputDecoration(
          hintText: hint,
          counterText: '',
          enabledBorder: bad == key ? OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.out)) : null,
        ),
      );

  Widget _head(String title, [String? sub]) => Column(children: [
        const VaultLogo(size: 56),
        const SizedBox(height: 14),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: C.ink)),
        if (sub != null) ...[const SizedBox(height: 6), Text(sub, textAlign: TextAlign.center, style: const TextStyle(color: C.dim, fontSize: 14))],
        const SizedBox(height: 18),
      ]);

  List<Widget> _login_() => [
        _head(t('loginT'), t('loginP')),
        _field(le, t('em'), 'le', kt: TextInputType.emailAddress, hints: const [AutofillHints.username]),
        const SizedBox(height: 14),
        PwField(c: lp, hint: t('pw'), action: TextInputAction.done, onSubmit: (_) => _login(), invalid: bad == 'lp'),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          InkWell(
            onTap: () => setState(() => remember = !remember),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _Check(remember),
              const SizedBox(width: 8),
              Text(t('rem'), style: const TextStyle(color: Color(0xFFA9C9BB), fontSize: 13)),
            ]),
          ),
          LinkText(t('forgot'), () => _m(AuthMode.forgot)),
        ]),
        const SizedBox(height: 12),
        MsgBox(err),
        MsgBox(ok, ok: true),
        const SizedBox(height: 12),
        PrimaryButton(label: t('loginBtn'), onTap: _login, busy: busy),
        const SizedBox(height: 6),
        LinkText(t('toReg'), () => _m(AuthMode.reg)),
      ];

  List<Widget> _reg_() {
    final s = pwScore(rp.text);
    return [
      _head(t('regT'), t('regP')),
      Row(children: [
        Expanded(child: _field(rf, t('fn'), 'rf', hints: const [AutofillHints.givenName], max: 30)),
        const SizedBox(width: 10),
        Expanded(child: _field(rl, t('ln'), 'rl', hints: const [AutofillHints.familyName], max: 30)),
      ]),
      const SizedBox(height: 14),
      _field(re, t('em'), 're', kt: TextInputType.emailAddress, hints: const [AutofillHints.username]),
      const SizedBox(height: 14),
      PwField(c: rp, hint: t('pw'), onChanged: (_) => setState(() {}), invalid: bad == 'rp'),
      const SizedBox(height: 10),
      Row(children: [
        for (var i = 1; i <= 4; i++)
          Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i == 4 ? 8 : 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: i <= s ? (s == 1 ? C.out : s == 2 ? C.warn : s == 3 ? C.accent : C.accent2) : Colors.white.withOpacity(.09),
              ),
            ),
          ),
        SizedBox(width: 64, child: Text(s == 0 ? '' : t('st$s'), textAlign: TextAlign.right, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF7FA797)))),
      ]),
      const SizedBox(height: 10),
      PwField(c: rp2, hint: t('pw2'), action: TextInputAction.done, invalid: bad == 'rp2'),
      const SizedBox(height: 14),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(onTap: () => setState(() => consent = !consent), child: _Check(consent)),
        const SizedBox(width: 10),
        Expanded(
          child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
            Text('${t('cons1')} ', style: const TextStyle(color: Color(0xFFA9C9BB), fontSize: 13)),
            LinkText(t('terms'), () => _doc(true)),
            Text(' ${t('cons2')} ', style: const TextStyle(color: Color(0xFFA9C9BB), fontSize: 13)),
            LinkText(t('privL'), () => _doc(false)),
            Text(t('cons3'), style: const TextStyle(color: Color(0xFFA9C9BB), fontSize: 13)),
          ]),
        ),
      ]),
      const SizedBox(height: 14),
      NoteBox(t('devNote')),
      const SizedBox(height: 12),
      MsgBox(err),
      const SizedBox(height: 12),
      PrimaryButton(label: t('regBtn'), onTap: _register, busy: busy),
      const SizedBox(height: 6),
      LinkText(t('toLogin'), () => _m(AuthMode.login)),
    ];
  }

  List<Widget> _fg_() => [
        _head(t('fgT')),
        NoteBox(t('fgNote')),
        const SizedBox(height: 14),
        _field(fe, t('em'), 'fe', kt: TextInputType.emailAddress),
        const SizedBox(height: 14),
        PwField(c: fp, hint: t('newPw'), invalid: bad == 'fp'),
        const SizedBox(height: 14),
        PwField(c: fp2, hint: t('pw2'), action: TextInputAction.done, invalid: bad == 'fp2'),
        const SizedBox(height: 12),
        MsgBox(err),
        const SizedBox(height: 12),
        PrimaryButton(label: t('fgBtn'), onTap: _reset, busy: busy),
        const SizedBox(height: 6),
        LinkText(t('back'), () => _m(AuthMode.login)),
      ];

  @override
  Widget build(BuildContext context) {
    final body = mode == AuthMode.login ? _login_() : mode == AuthMode.reg ? _reg_() : _fg_();
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: VaultBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  alignment: Alignment.topCenter,
                  child: Column(key: ValueKey(mode), crossAxisAlignment: CrossAxisAlignment.stretch, children: body),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Check extends StatelessWidget {
  final bool on;
  const _Check(this.on);
  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 22,
        height: 22,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(7), color: on ? C.accent2 : const Color(0x0AFFFFFF), border: Border.all(color: on ? C.accent2 : const Color(0x596EE7B7), width: 1.5)),
        child: on ? const Icon(Icons.check_rounded, size: 16, color: Color(0xFF02130D)) : null,
      );
}

/* ================================= INTRO (3 pages) ================================= */
class IntroScreen extends StatefulWidget {
  final Future<bool> Function() onFinish;
  const IntroScreen({super.key, required this.onFinish});
  @override
  State<IntroScreen> createState() => _IntroState();
}

class _IntroState extends State<IntroScreen> {
  final _pc = PageController();
  int _i = 0;
  bool _busy = false;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await widget.onFinish();
    if (!mounted) return;
    if (!ok) {
      setState(() => _busy = false);
      toast(context, t('eSave'));
    }
  }

  void _next() {
    if (_i < 2) {
      _pc.nextPage(duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<(String, String, Widget)> pages = [
      (t('i1t'), t('i1d'), const _Vis1()),
      (t('i2t'), t('i2d'), const _Vis2()),
      (t('i3t'), t('i3d'), const _Vis3()),
    ];
    return Scaffold(
      body: VaultBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
                child: Column(children: [
                  Row(children: [
                    Expanded(
                      child: Row(children: [
                        for (var k = 0; k < 3; k++)
                          Expanded(
                            child: Container(
                              height: 3,
                              margin: EdgeInsets.only(right: k == 2 ? 0 : 6),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: Stack(children: [
                                  Container(color: Colors.white.withOpacity(.12)),
                                  AnimatedFractionallySizedBox(
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeOutCubic,
                                    alignment: Alignment.centerLeft,
                                    widthFactor: k <= _i ? 1 : 0,
                                    child: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [C.accent2, Color(0xFF6EE7B7)]))),
                                  ),
                                ]),
                              ),
                            ),
                          ),
                      ]),
                    ),
                    const SizedBox(width: 16),
                    TextButton(onPressed: _busy ? null : _finish, child: Text(t('skip'), style: const TextStyle(color: C.dim, fontWeight: FontWeight.w600, fontSize: 13.5))),
                  ]),
                  Expanded(
                    child: PageView.builder(
                      controller: _pc,
                      itemCount: 3,
                      onPageChanged: (v) => setState(() => _i = v),
                      itemBuilder: (context, k) {
                        final p = pages[k];
                        return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          SizedBox(height: math.min(MediaQuery.of(context).size.height * .4, 330), child: Center(child: p.$3)),
                          const SizedBox(height: 22),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(p.$1, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, height: 1.12, color: Color(0xFFF4FFF9), letterSpacing: -.3)),
                              const SizedBox(height: 10),
                              Text(p.$2, style: const TextStyle(fontSize: 15.5, height: 1.55, color: Color(0xFF9BBDAE))),
                            ]),
                          ),
                        ]);
                      },
                    ),
                  ),
                  PrimaryButton(label: t(_i >= 2 ? 'startI' : 'nextI'), onTap: _next, busy: _busy),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

BoxDecoration _glass([double r = 22]) => BoxDecoration(
      borderRadius: BorderRadius.circular(r),
      color: const Color(0x0DFFFFFF),
      border: Border.all(color: const Color(0x286EE7B7)),
    );

class _SparkPainter extends CustomPainter {
  final double k;
  _SparkPainter(this.k);
  @override
  void paint(Canvas canvas, Size s) {
    final pts = <Offset>[const Offset(0, .78), const Offset(.12, .72), const Offset(.31, .35), const Offset(.5, .46), const Offset(.65, .82), const Offset(.8, .43), const Offset(.9, .2), const Offset(1, .15)];
    final path = Path()..moveTo(pts.first.dx * s.width, pts.first.dy * s.height);
    for (var i = 1; i < pts.length; i++) {
      final p0 = pts[i - 1], p1 = pts[i];
      final mx = (p0.dx + p1.dx) / 2 * s.width;
      path.cubicTo(mx, p0.dy * s.height, mx, p1.dy * s.height, p1.dx * s.width, p1.dy * s.height);
    }
    final m = path.computeMetrics().first;
    final part = m.extractPath(0, m.length * k);
    final area = Path.from(part);
    final end = part.computeMetrics().isEmpty ? Offset.zero : part.computeMetrics().first.getTangentForOffset(part.computeMetrics().first.length)?.position ?? Offset.zero;
    area.lineTo(end.dx, s.height);
    area.lineTo(0, s.height);
    area.close();
    canvas.drawPath(area, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x8034D399), Color(0x0034D399)]).createShader(Offset.zero & s));
    canvas.drawPath(part, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.6..strokeCap = StrokeCap.round..color = const Color(0xFF6EE7B7));
  }

  @override
  bool shouldRepaint(covariant _SparkPainter o) => o.k != k;
}

class _Vis1 extends StatelessWidget {
  const _Vis1();
  Widget _row(IconData ic, Color col, String label, String val, double delay) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Interval(delay, 1, curve: Curves.easeOutCubic),
        builder: (c, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: child)),
        child: Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: _glass(16),
          child: Row(children: [
            Container(width: 30, height: 30, decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: col.withOpacity(.18)), child: Icon(ic, size: 16, color: col)),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFFCFE8DC)))),
            Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: col)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 290,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0x4710B981), Color(0x33064E3B)]),
              border: Border.all(color: const Color(0x406EE7B7)),
              boxShadow: [BoxShadow(color: C.accent2.withOpacity(.25), blurRadius: 50, spreadRadius: -12)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t('vBal'), style: const TextStyle(color: Color(0xFF9BD4BD), fontSize: 12)),
              const SizedBox(height: 2),
              const Text('4 820 000', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -.3)),
              const SizedBox(height: 10),
              SizedBox(
                height: 56,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1600),
                  curve: Curves.easeInOut,
                  builder: (c, v, _) => CustomPaint(size: Size.infinite, painter: _SparkPainter(v)),
                ),
              ),
            ]),
          ),
          _row(Icons.arrow_upward_rounded, const Color(0xFF6EE7B7), t('vIn'), '+1 200 000', .2),
          _row(Icons.arrow_downward_rounded, const Color(0xFFFCD34D), t('vOut'), '− 380 000', .4),
        ]),
      );
}

class _DonutPainter extends CustomPainter {
  final List<double> parts; // fractions
  final List<Color> cols;
  final double k;
  final double stroke;
  _DonutPainter(this.parts, this.cols, this.k, {this.stroke = 13});
  @override
  void paint(Canvas canvas, Size s) {
    final r = (math.min(s.width, s.height) - stroke) / 2;
    final rect = Rect.fromCircle(center: s.center(Offset.zero), radius: r);
    canvas.drawCircle(rect.center, r, Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..color = const Color(0x12FFFFFF));
    var a = -math.pi / 2;
    final gap = parts.length > 1 ? .05 : 0.0;
    for (var i = 0; i < parts.length; i++) {
      final sw = (parts[i] * 2 * math.pi - gap) * k;
      if (sw > 0) canvas.drawArc(rect, a, sw, false, Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.round..color = cols[i % cols.length]);
      a += parts[i] * 2 * math.pi;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter o) => o.k != k || o.parts != parts;
}

class _Vis2 extends StatelessWidget {
  const _Vis2();
  @override
  Widget build(BuildContext context) {
    const hs = [.44, .72, .56, .9, .66];
    return SizedBox(
      width: 310,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _glass(),
          child: Row(children: [
            SizedBox(
              width: 108,
              height: 108,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutCubic,
                builder: (c, v, _) => CustomPaint(painter: _DonutPainter(const [.46, .28, .14], const [C.accent, C.warn, Color(0xFF60A5FA)], v)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: SizedBox(
                height: 96,
                child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  for (var i = 0; i < hs.length; i++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i == hs.length - 1 ? 0 : 7),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: hs[i]),
                          duration: Duration(milliseconds: 900 + i * 100),
                          curve: Curves.easeOutCubic,
                          builder: (c, v, _) => FractionallySizedBox(
                            heightFactor: v,
                            alignment: Alignment.bottomCenter,
                            child: Container(decoration: BoxDecoration(borderRadius: const BorderRadius.vertical(top: Radius.circular(7), bottom: Radius.circular(3)), gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [C.accent, C.deep]))),
                          ),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          decoration: _glass(20),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(t('vGoal'), style: const TextStyle(fontSize: 13, color: Color(0xFFCFE8DC))),
              const Text('68%', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF6EE7B7))),
            ]),
            const SizedBox(height: 9),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: .68),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOutCubic,
              builder: (c, v, _) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: v, minHeight: 8, backgroundColor: Colors.white.withOpacity(.08), valueColor: const AlwaysStoppedAnimation(C.accent)),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Vis3 extends StatefulWidget {
  const _Vis3();
  @override
  State<_Vis3> createState() => _Vis3State();
}

class _Vis3State extends State<_Vis3> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = math.min(MediaQuery.of(context).size.width * .8, 290.0);
    const icons = [Icons.credit_card_rounded, Icons.bar_chart_rounded, Icons.track_changes_rounded, Icons.account_balance_wallet_rounded, Icons.groups_rounded, Icons.shield_rounded];
    return SizedBox(
      width: size,
      height: size,
      child: Stack(alignment: Alignment.center, children: [
        Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0x286EE7B7)))),
        Container(width: size * .66, height: size * .66, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0x1A6EE7B7)))),
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final ang = _c.value * 2 * math.pi;
            return Stack(children: [
              for (var i = 0; i < icons.length; i++)
                Positioned(
                  left: size / 2 + (size / 2) * math.cos(ang + i * math.pi / 3 - math.pi / 2) - 22,
                  top: size / 2 + (size / 2) * math.sin(ang + i * math.pi / 3 - math.pi / 2) - 22,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color(0xFF08201A), border: Border.all(color: const Color(0x476EE7B7)), boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 20, spreadRadius: -6, offset: Offset(0, 8))]),
                    child: Icon(icons[i], size: 20, color: const Color(0xFF6EE7B7)),
                  ),
                ),
            ]);
          },
        ),
        Container(
          width: size * .34,
          height: size * .34,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: const RadialGradient(colors: [Color(0x5910B981), Color(0x33064E3B)]), border: Border.all(color: const Color(0x4D6EE7B7)), boxShadow: const [BoxShadow(color: Color(0x5910B981), blurRadius: 50)]),
          child: Center(child: VaultLogo(size: size * .18)),
        ),
      ]),
    );
  }
}

/* ================================ CARD REVEAL ================================ */
class CardRevealScreen extends StatefulWidget {
  final VCard card;
  final VoidCallback onEnter;
  const CardRevealScreen({super.key, required this.card, required this.onEnter});
  @override
  State<CardRevealScreen> createState() => _CardRevealState();
}

class _CardRevealState extends State<CardRevealScreen> with TickerProviderStateMixin {
  late final AnimationController _in = AnimationController(vsync: this, duration: const Duration(milliseconds: 5600))..forward();
  late final AnimationController _out = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  late final AnimationController _flash = AnimationController(vsync: this, duration: const Duration(milliseconds: 950));
  bool _leaving = false;

  @override
  void dispose() {
    _in.dispose();
    _out.dispose();
    _flash.dispose();
    super.dispose();
  }

  double _iv(double a, double b, Curve c) => c.transform(((_in.value - a) / (b - a)).clamp(0.0, 1.0));

  Future<void> _enter() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    HapticFeedback.lightImpact();
    await _out.forward();
    await _flash.forward();
    if (mounted) widget.onEnter();
  }

  @override
  Widget build(BuildContext context) {
    final w = math.min(MediaQuery.of(context).size.width * .88, 380.0);
    return Scaffold(
      body: VaultBackdrop(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: Listenable.merge([_in, _out, _flash]),
            builder: (context, _) {
              final k = _iv(0.05, 0.5, Curves.easeOutCubic);
              final halo = _iv(0.1, 0.7, Curves.easeOut);
              final txt = _iv(0.5, 0.68, Curves.easeOutCubic);
              final btn = _iv(0.6, 0.78, Curves.easeOutCubic);
              final o = Curves.easeIn.transform(_out.value);
              final m = Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..multiply(Matrix4.translationValues(0, -20 * (1 - k) - 520 * o, 1200 * (1 - k) + 150 * o * -1))
                ..multiply(Matrix4.rotationY(-300 * math.pi / 180 * (1 - k)))
                ..multiply(Matrix4.rotationX((20 * (1 - k) + 35 * o) * math.pi / 180));
              final cardOpacity = (k < .25 ? k / .25 : 1.0) * (1 - o);
              final fade = 1 - o;
              return Stack(fit: StackFit.expand, children: [
                Center(
                  child: Opacity(
                    opacity: halo * .85,
                    child: Transform.scale(
                      scale: .3 + .7 * halo,
                      child: Container(width: 620, height: 620, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0x5234D399), Color(0x1410B981), Color(0x0034D399)], stops: [0, .45, .68]))),
                    ),
                  ),
                ),
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Opacity(
                    opacity: cardOpacity.clamp(0.0, 1.0),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: m,
                      child: Container(
                        width: w,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(w * .06), boxShadow: [BoxShadow(color: C.accent.withOpacity(.35 * halo), blurRadius: 40)]),
                        child: VaultCardFace(card: widget.card, revealed: false),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Opacity(
                    opacity: (txt * fade).clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, 16 * (1 - txt)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Column(children: [
                            Text(t('cardT'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, height: 1.15, color: Color(0xFFF4FFF9))),
                            const SizedBox(height: 10),
                            Text(t('cardP'), textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF9BBDAE), fontSize: 15)),
                            const SizedBox(height: 12),
                            NoteBox(t('cardNote')),
                          ]),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Opacity(
                    opacity: (btn * fade).clamp(0.0, 1.0),
                    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400), child: PrimaryButton(label: t('cardGo'), onTap: btn > .6 ? _enter : null))),
                  ),
                ]),
                if (_flash.value > 0)
                  Opacity(
                    opacity: Curves.easeOut.transform((_flash.value / .35).clamp(0.0, 1.0)),
                    child: Container(
                      decoration: const BoxDecoration(gradient: RadialGradient(colors: [Color(0x66107858), C.bg], stops: [0, .62])),
                      child: Center(child: Transform.scale(scale: .9 + .14 * _flash.value, child: Container(decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: C.accent.withOpacity(.45), blurRadius: 60)]), child: const VaultLogo(size: 110)))),
                    ),
                  ),
              ]);
            },
          ),
        ),
      ),
    );
  }
}

/* ====================================================================== */
/*  APP SHELL: Home · Transactions · Analytics · Vault (card) · Profile     */
/* ====================================================================== */
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VaultApp());
}

double? parseAmount(String s) {
  final v = double.tryParse(s.trim().replaceAll(RegExp(r'\s'), '').replaceAll(',', '.'));
  if (v == null || v.isNaN || v.isInfinite) return null;
  return v;
}

/* ------------------------------ shared bits ------------------------------ */
class MonthBar extends StatelessWidget {
  final String mk;
  final void Function(int) onShift;
  const MonthBar({super.key, required this.mk, required this.onShift});
  @override
  Widget build(BuildContext context) {
    final p = mk.split('-');
    final isCur = mk == monthKeyOf(DateTime.now());
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(onPressed: () => onShift(-1), icon: const Icon(Icons.chevron_left_rounded), color: C.dim, visualDensity: VisualDensity.compact),
      Text('${monthName(int.parse(p[1]))} ${p[0]}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
      IconButton(onPressed: isCur ? null : () => onShift(1), icon: const Icon(Icons.chevron_right_rounded), color: C.dim, visualDensity: VisualDensity.compact),
    ]);
  }
}

class Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  const Glass({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.margin = EdgeInsets.zero});
  @override
  Widget build(BuildContext context) => Container(margin: margin, padding: padding, decoration: _glass(20), child: child);
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 10),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          if (trailing != null) trailing!,
        ]),
      );
}

class EmptyState extends StatelessWidget {
  final String title, desc;
  const EmptyState(this.title, this.desc, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        child: Column(children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(shape: BoxShape.circle, color: C.accent.withOpacity(.12)), child: const Icon(Icons.receipt_long_rounded, color: C.accent)),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 4),
          Text(desc, textAlign: TextAlign.center, style: const TextStyle(color: C.dim, fontSize: 13)),
        ]),
      );
}

class TxTile extends StatelessWidget {
  final Tx x;
  final VoidCallback? onTap;
  const TxTile(this.x, {super.key, this.onTap});
  @override
  Widget build(BuildContext context) {
    final c = catOf(x.t, x.c);
    final inc = x.t == 'in';
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: c.color.withOpacity(.16)), child: Icon(c.icon, color: c.color, size: 21)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
              if (x.n.isNotEmpty) Text(x.n, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: C.dim, fontSize: 12.5)),
            ]),
          ),
          Text('${inc ? '+' : '−'}${grp(x.a)} ${curUnit()}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: inc ? C.accent : C.out)),
        ]),
      ),
    );
  }
}

/* --------------------------------- HOME --------------------------------- */
class NetSparkPainter extends CustomPainter {
  final List<double> pts;
  NetSparkPainter(this.pts);
  @override
  void paint(Canvas canvas, Size s) {
    if (pts.length < 2) return;
    var lo = pts.reduce(math.min), hi = pts.reduce(math.max);
    lo = math.min(lo, 0);
    hi = math.max(hi, 0);
    if (hi == lo) hi = lo + 1;
    const pad = 6.0;
    double x(int i) => i / (pts.length - 1) * s.width;
    double y(double v) => pad + (s.height - 2 * pad) * (1 - (v - lo) / (hi - lo));
    final path = Path()..moveTo(x(0), y(pts[0]));
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(x(i), y(pts[i]));
    }
    final zero = y(0);
    final area = Path.from(path)..lineTo(x(pts.length - 1), zero)..lineTo(0, zero)..close();
    canvas.drawLine(Offset(0, zero), Offset(s.width, zero), Paint()..color = Colors.white24..strokeWidth = 1);
    canvas.drawPath(area, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.white.withOpacity(.32), Colors.white.withOpacity(0)]).createShader(Offset.zero & s));
    canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.2..strokeJoin = StrokeJoin.round..strokeCap = StrokeCap.round..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant NetSparkPainter o) => !listEquals(o.pts, pts);
}

class CatDonut extends StatelessWidget {
  final Map<String, double> data;
  final String type;
  const CatDonut({super.key, required this.data, this.type = 'out'});
  @override
  Widget build(BuildContext context) {
    final total = data.values.fold<double>(0, (a, b) => a + b);
    final es = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (total <= 0) return Padding(padding: const EdgeInsets.all(12), child: Text(t('noData'), style: const TextStyle(color: C.dim)));
    return Row(children: [
      SizedBox(
        width: 120,
        height: 120,
        child: TweenAnimationBuilder<double>(
          key: ValueKey(total),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (c, k, _) => CustomPaint(painter: _DonutPainter(es.map((e) => e.value / total).toList(), es.map((e) => catOf(type, e.key).color).toList(), k, stroke: 16)),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(children: [
          for (final e in es.take(5))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                Container(width: 9, height: 9, decoration: BoxDecoration(shape: BoxShape.circle, color: catOf(type, e.key).color)),
                const SizedBox(width: 8),
                Expanded(child: Text(catOf(type, e.key).name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                Text('${(e.value / total * 100).round()}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.dim)),
              ]),
            ),
        ]),
      ),
    ]);
  }
}

class HomeTab extends StatelessWidget {
  final String mk;
  final void Function(int) onShift;
  final Future<void> Function([Tx?]) onAdd;
  final VoidCallback onSeeAll;
  final VoidCallback onPlans;
  const HomeTab({super.key, required this.mk, required this.onShift, required this.onAdd, required this.onSeeAll, required this.onPlans});

  @override
  Widget build(BuildContext context) {
    final p = app.profile!;
    final s = app.sums(mk);
    final parts = mk.split('-');
    final y = int.parse(parts[0]), m = int.parse(parts[1]);
    final isCur = mk == monthKeyOf(DateTime.now());
    final n = daysIn(y, m), elapsed = isCur ? DateTime.now().day : n;
    final net = <double>[0];
    var cum = 0.0;
    final list = app.listOf(mk);
    for (var d = 1; d <= elapsed; d++) {
      for (final x in list.where((e) => e.d == '$mk-${two(d)}')) {
        cum += x.t == 'in' ? x.a : -x.a;
      }
      net.add(cum);
    }
    final lim = p.limit;
    final pct = lim > 0 ? s.o / lim : 0.0;
    final recent = (app.txs.toList()..sort((a, b) => b.ts.compareTo(a.ts))).take(5).toList();
    final monthCount = app.listOf(monthKeyOf(DateTime.now())).length;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
      Row(children: [
        const VaultLogo(size: 34),
        const SizedBox(width: 10),
        Expanded(child: Text('${t('hello')}, ${p.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis)),
        PlanChip(onTap: onPlans),
      ]),
      Align(alignment: Alignment.centerRight, child: MonthBar(mk: mk, onShift: onShift)),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF047857), Color(0xFF065F46), Color(0xFF064E3B)]),
          boxShadow: [BoxShadow(color: C.accent2.withOpacity(.3), blurRadius: 40, spreadRadius: -10, offset: const Offset(0, 18))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t('balance'), style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13)),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: s.i - s.o),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (c, v, _) => FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text('${grp(v)} ${curUnit()}', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -.5))),
          ),
          const SizedBox(height: 10),
          SizedBox(height: 64, width: double.infinity, child: CustomPaint(painter: NetSparkPainter(net))),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _MiniStat(Icons.arrow_upward_rounded, t('income'), grp(s.i), const Color(0xFFA7F3D0))),
            const SizedBox(width: 10),
            Expanded(child: _MiniStat(Icons.arrow_downward_rounded, t('expense'), grp(s.o), const Color(0xFFFECACA))),
          ]),
        ]),
      ),
      if (lim > 0) ...[
        const SizedBox(height: 12),
        Glass(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t('limit'), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: pct.clamp(0.0, 1.0), minHeight: 8, backgroundColor: Colors.white.withOpacity(.08), valueColor: AlwaysStoppedAnimation(pct > 1 ? C.out : pct >= .75 ? C.warn : C.accent))),
            const SizedBox(height: 8),
            Text(
              pct > 1 ? t('limitOver', {'n': grp(s.o - lim), 'u': curUnit()}) : t('limitSpent', {'a': grp(s.o), 'b': grp(lim), 'c': grp(lim - s.o), 'u': curUnit()}),
              style: TextStyle(color: pct > 1 ? C.out : C.dim, fontSize: 12.5),
            ),
          ]),
        ),
      ],
      if (!p.isMax) ...[
        const SizedBox(height: 12),
        Glass(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t('quota', {'n': '$monthCount', 'm': '$kFreeTxPerMonth'}), style: const TextStyle(fontSize: 12.5, color: C.dim)),
            const SizedBox(height: 8),
            ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: (monthCount / kFreeTxPerMonth).clamp(0.0, 1.0), minHeight: 6, backgroundColor: Colors.white.withOpacity(.08), valueColor: AlwaysStoppedAnimation(monthCount >= kFreeTxPerMonth ? C.out : monthCount >= kFreeTxPerMonth * .8 ? C.warn : C.accent))),
          ]),
        ),
      ],
      SectionTitle(t('byCat')),
      Glass(child: CatDonut(data: app.byCat(mk, 'out'))),
      SectionTitle(t('recent'), trailing: LinkText(t('seeAll'), onSeeAll)),
      Glass(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: recent.isEmpty
            ? EmptyState(t('emptyTx'), t('emptyTxD'))
            : Column(children: [for (final x in recent) TxTile(x, onTap: () => onAdd(x))]),
      ),
    ]);
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color col;
  const _MiniStat(this.icon, this.label, this.value, this.col);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color(0x26000000)),
        child: Row(children: [
          Icon(icon, size: 18, color: col),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xB3FFFFFF))),
              FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white))),
            ]),
          ),
        ]),
      );
}

/* ----------------------------- TRANSACTIONS ----------------------------- */
class TxTab extends StatefulWidget {
  final String mk;
  final void Function(int) onShift;
  final Future<void> Function([Tx?]) onEdit;
  const TxTab({super.key, required this.mk, required this.onShift, required this.onEdit});
  @override
  State<TxTab> createState() => _TxTabState();
}

class _TxTabState extends State<TxTab> {
  String _q = '';
  String _type = ''; // '', 'in', 'out'

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    var list = app.listOf(widget.mk).where((x) {
      if (_type.isNotEmpty && x.t != _type) return false;
      if (q.isEmpty) return true;
      return x.n.toLowerCase().contains(q) || catOf(x.t, x.c).name.toLowerCase().contains(q) || grp(x.a).contains(q);
    }).toList()
      ..sort((a, b) => b.d != a.d ? b.d.compareTo(a.d) : b.ts.compareTo(a.ts));
    final groups = <String, List<Tx>>{};
    for (final x in list) {
      groups.putIfAbsent(x.d, () => []).add(x);
    }
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(children: [
          Expanded(child: Text(t('navTx'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
          MonthBar(mk: widget.mk, onShift: widget.onShift),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: TextField(onChanged: (v) => setState(() => _q = v), decoration: InputDecoration(hintText: t('search2'), prefixIcon: const Icon(Icons.search_rounded, color: C.mute))),
      ),
      SizedBox(
        height: 40,
        child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
          for (final f in [('', t('all')), ('in', t('income')), ('out', t('expense'))])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(f.$2),
                selected: _type == f.$1,
                onSelected: (_) => setState(() => _type = f.$1),
                selectedColor: C.accent.withOpacity(.2),
                backgroundColor: const Color(0x0AFFFFFF),
                side: BorderSide(color: _type == f.$1 ? C.accent : C.line),
                labelStyle: TextStyle(color: _type == f.$1 ? Colors.white : C.dim, fontWeight: FontWeight.w600),
              ),
            ),
        ]),
      ),
      Expanded(
        child: groups.isEmpty
            ? Center(child: EmptyState(t('emptyTx'), t('emptyTxD')))
            : ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
                for (final e in groups.entries) ...[
                  Padding(padding: const EdgeInsets.fromLTRB(4, 14, 4, 6), child: Text(niceDate(e.key), style: const TextStyle(color: C.dim, fontWeight: FontWeight.w700, fontSize: 12.5))),
                  Glass(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    child: Column(children: [
                      for (final x in e.value)
                        Dismissible(
                          key: ValueKey(x.id),
                          direction: DismissDirection.endToStart,
                          background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 18), color: C.out.withOpacity(.25), child: const Icon(Icons.delete_rounded, color: C.out)),
                          onDismissed: (_) {
                            final copy = x;
                            app.removeTx(x.id);
                            ScaffoldMessenger.of(context)
                              ..clearSnackBars()
                              ..showSnackBar(SnackBar(content: Text(t('deleted')), action: SnackBarAction(label: t('undo'), textColor: C.accent, onPressed: () => app.addTx(copy))));
                          },
                          child: TxTile(x, onTap: () => widget.onEdit(x)),
                        ),
                    ]),
                  ),
                ],
              ]),
      ),
    ]);
  }
}

/* ------------------------------ ADD / EDIT ------------------------------ */
class TxSheet extends StatefulWidget {
  final Tx? edit;
  const TxSheet({super.key, this.edit});
  @override
  State<TxSheet> createState() => _TxSheetState();
}

class _TxSheetState extends State<TxSheet> {
  late String type = widget.edit?.t ?? 'out';
  late String cat = widget.edit?.c ?? '';
  late String date = widget.edit?.d ?? todayStr();
  late final amt = TextEditingController(text: widget.edit == null ? '' : widget.edit!.a.toStringAsFixed(kNoDec.contains(app.cur) ? 0 : 2));
  late final note = TextEditingController(text: widget.edit?.n ?? '');
  String err = '';
  String wallet = '';

  @override
  void dispose() {
    amt.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final p = date.split('-');
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2])),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 366)),
    );
    if (d != null) setState(() => date = dayKey(d));
  }

  Future<void> _save() async {
    final a = parseAmount(amt.text);
    if (a == null || a <= 0 || a > 1e12) {
      setState(() => err = t('eAmount'));
      return;
    }
    final cats = catsOf(type);
    final c = cat.isEmpty ? cats.last.id : cat;
    if (widget.edit == null && kEnforceFreeQuota && !app.profile!.isMax) {
      final n = app.listOf(date.substring(0, 7)).length;
      if (n >= kFreeTxPerMonth) {
        setState(() => err = t('quotaFull', {'m': '$kFreeTxPerMonth'}));
        return;
      }
    }
    final nav = Navigator.of(context);
    if (widget.edit != null) {
      final e = widget.edit!;
      final ex = Map<String, dynamic>.from(e.ex);
      await app.updateTx(Tx(id: e.id, t: type, a: r2(a), c: c, n: note.text.trim(), d: date, ts: e.ts, ex: ex));
    } else {
      final ex = <String, dynamic>{};
      if (wallet.isNotEmpty) ex['w'] = wallet;
      await app.addTx(Tx(id: newId(), t: type, a: r2(a), c: c, n: note.text.trim(), d: date, ts: DateTime.now().millisecondsSinceEpoch, ex: ex));
      limitCheck(context);
    }
    nav.pop();
  }

  Future<void> _delete() async {
    final nav = Navigator.of(context);
    await app.removeTx(widget.edit!.id);
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final cats = catsOf(type);
    if (cat.isEmpty || !cats.any((c) => c.id == cat)) cat = cats.first.id;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 14),
          Text(widget.edit == null ? t('addTx') : t('editTx'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _SegBtn(label: t('expense'), on: type == 'out', onTap: () => setState(() => type = 'out'))),
            const SizedBox(width: 8),
            Expanded(child: _SegBtn(label: t('income'), on: type == 'in', onTap: () => setState(() => type = 'in'))),
          ]),
          const SizedBox(height: 14),
          TextField(
            controller: amt,
            autofocus: widget.edit == null,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            decoration: InputDecoration(hintText: t('amount'), suffixText: curUnit(), suffixStyle: const TextStyle(color: C.dim, fontSize: 15)),
          ),
          const SizedBox(height: 14),
          Text(t('category').toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: .7, color: Color(0xFF7FA797))),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in cats)
              ChoiceChip(
                avatar: Icon(c.icon, size: 16, color: c.color),
                label: Text(c.name),
                selected: cat == c.id,
                onSelected: (_) => setState(() => cat = c.id),
                selectedColor: c.color.withOpacity(.22),
                backgroundColor: const Color(0x0AFFFFFF),
                side: BorderSide(color: cat == c.id ? c.color : C.line),
                labelStyle: TextStyle(color: cat == c.id ? Colors.white : C.dim, fontWeight: FontWeight.w600, fontSize: 13),
              ),
          ]),
          const SizedBox(height: 14),
          TextField(controller: note, maxLength: 80, decoration: InputDecoration(hintText: t('note'), counterText: '')),
          if (widget.edit == null && app.profile!.isUltra && app.profile!.lst('wallets').isNotEmpty) ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: wallet,
              isExpanded: true,
              dropdownColor: C.bg2,
              decoration: const InputDecoration(hintText: 'Hamyon'),
              items: [
                const DropdownMenuItem(value: '', child: Text('Hamyon: tanlanmagan')),
                for (final w in app.profile!.lst('wallets')) DropdownMenuItem(value: '${w['id']}', child: Text('${w['name']}')),
              ],
              onChanged: (v) => setState(() => wallet = v ?? ''),
            ),
          ],
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_rounded, size: 18),
            label: Text('${t('date')}: ${niceDate(date)}'),
            style: OutlinedButton.styleFrom(foregroundColor: C.ink, side: const BorderSide(color: C.line), minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          ),
          if (err.isNotEmpty) ...[const SizedBox(height: 12), MsgBox(err)],
          const SizedBox(height: 16),
          PrimaryButton(label: t('save'), onTap: _save),
          if (widget.edit != null) ...[
            const SizedBox(height: 6),
            TextButton(onPressed: _delete, child: Text(t('delete'), style: const TextStyle(color: C.out, fontWeight: FontWeight.w700))),
          ],
        ]),
      ),
    );
  }
}

/* -------------------------------- ANALYTICS -------------------------------- */
class _BarsPainter extends CustomPainter {
  final List<double> ins, outs;
  final List<String> labels;
  _BarsPainter(this.ins, this.outs, this.labels);
  @override
  void paint(Canvas canvas, Size s) {
    final mx = [...ins, ...outs].fold<double>(1, math.max);
    final n = ins.length;
    final slot = s.width / n;
    const base = 22.0;
    final h = s.height - base;
    for (var i = 0; i < n; i++) {
      final cx = slot * i + slot / 2;
      final bw = math.min(14.0, slot / 3);
      final hi = h * (ins[i] / mx), ho = h * (outs[i] / mx);
      canvas.drawRRect(RRect.fromRectAndCorners(Rect.fromLTWH(cx - bw - 1.5, h - hi, bw, hi), topLeft: const Radius.circular(5), topRight: const Radius.circular(5)), Paint()..color = C.accent);
      canvas.drawRRect(RRect.fromRectAndCorners(Rect.fromLTWH(cx + 1.5, h - ho, bw, ho), topLeft: const Radius.circular(5), topRight: const Radius.circular(5)), Paint()..color = C.out.withOpacity(.85));
      final tp = TextPainter(text: TextSpan(text: labels[i], style: const TextStyle(color: C.dim, fontSize: 11)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, h + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter o) => true;
}

class StatsTab extends StatelessWidget {
  final String mk;
  final void Function(int) onShift;
  const StatsTab({super.key, required this.mk, required this.onShift});
  @override
  Widget build(BuildContext context) {
    final p = mk.split('-');
    final y = int.parse(p[0]), m = int.parse(p[1]);
    final s = app.sums(mk);
    final byc = app.byCat(mk, 'out');
    final top = byc.entries.isEmpty ? null : (byc.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first;
    final isCur = mk == monthKeyOf(DateTime.now());
    final days = isCur ? DateTime.now().day : daysIn(y, m);
    final ins = <double>[], outs = <double>[], labels = <String>[];
    for (var k = 5; k >= 0; k--) {
      final d = DateTime(y, m - k, 1);
      final ss = app.sums(monthKeyOf(d));
      ins.add(ss.i);
      outs.add(ss.o);
      labels.add(monthName(d.month).substring(0, math.min(3, monthName(d.month).length)));
    }
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
      Row(children: [
        Expanded(child: Text(t('navStats'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
        MonthBar(mk: mk, onShift: onShift),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _StatCard(t('income'), '${grp(s.i)} ${curUnit()}', C.accent)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(t('expense'), '${grp(s.o)} ${curUnit()}', C.out)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _StatCard(t('topCat'), top == null ? '—' : catOf('out', top.key).name, C.warn)),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(t('avgDay'), '${grp(days > 0 ? s.o / days : 0)} ${curUnit()}', C.ink)),
      ]),
      SectionTitle(t('byCat')),
      Glass(child: CatDonut(data: byc)),
      SectionTitle(t('trend6')),
      Glass(
        child: Column(children: [
          SizedBox(height: 170, width: double.infinity, child: CustomPaint(painter: _BarsPainter(ins, outs, labels))),
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: C.accent, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 6),
            Text(t('income'), style: const TextStyle(color: C.dim, fontSize: 12.5)),
            const SizedBox(width: 18),
            Container(width: 10, height: 10, decoration: BoxDecoration(color: C.out, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 6),
            Text(t('expense'), style: const TextStyle(color: C.dim, fontSize: 12.5)),
          ]),
        ]),
      ),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color col;
  const _StatCard(this.label, this.value, this.col);
  @override
  Widget build(BuildContext context) => Glass(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: C.dim, fontSize: 12)),
          const SizedBox(height: 6),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: col))),
        ]),
      );
}

/* ================================ VAULT CARD ================================ */
class VaultCardFace extends StatelessWidget {
  final VCard card;
  final bool revealed;
  const VaultCardFace({super.key, required this.card, this.revealed = false});

  @override
  Widget build(BuildContext context) {
    final th = kCardThemes[card.theme] ?? kCardThemes['aurora']!;
    return AspectRatio(
      aspectRatio: 1.586,
      child: LayoutBuilder(builder: (context, bc) {
        final w = bc.maxWidth;
        final u = w / 340; // design unit
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(w * .06),
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: th),
            boxShadow: const [BoxShadow(color: Color(0x80000000), blurRadius: 30, offset: Offset(0, 14), spreadRadius: -10)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(w * .06),
            child: Stack(children: [
              Positioned(right: -w * .2, top: -w * .25, child: Container(width: w * .8, height: w * .8, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Colors.white.withOpacity(.22), Colors.white.withOpacity(0)])))),
              Positioned(left: -w * .25, bottom: -w * .35, child: Container(width: w * .9, height: w * .9, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Colors.black.withOpacity(.28), Colors.black.withOpacity(0)])))),
              Positioned.fill(child: CustomPaint(painter: _GridDots(u))),
              Padding(
                padding: EdgeInsets.all(20 * u),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.track_changes_rounded, color: Colors.white, size: 22 * u),
                    SizedBox(width: 6 * u),
                    Text('VAULT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17 * u, letterSpacing: 2.4)),
                    SizedBox(width: 8 * u),
                    Container(padding: EdgeInsets.symmetric(horizontal: 8 * u, vertical: 2 * u), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white54)), child: Text('VIRTUAL', style: TextStyle(color: Colors.white, fontSize: 9 * u, letterSpacing: 1.4, fontWeight: FontWeight.w600))),
                    const Spacer(),
                    Icon(Icons.wifi_rounded, color: Colors.white70, size: 22 * u),
                  ]),
                  SizedBox(height: 14 * u),
                  Container(
                    width: 42 * u,
                    height: 32 * u,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(6 * u), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF8E9AE), Color(0xFFD9B04F), Color(0xFFB98A2E)])),
                  ),
                  const Spacer(),
                  FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(revealed ? card.spaced : card.masked, style: TextStyle(color: Colors.white, fontSize: 21 * u, letterSpacing: 2.2, fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()]))),
                  SizedBox(height: 10 * u),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('KARTA EGASI', style: TextStyle(color: Colors.white60, fontSize: 8 * u, letterSpacing: 1.2)),
                        Text(card.name, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 13 * u, fontWeight: FontWeight.w700, letterSpacing: .6)),
                      ]),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('AMAL QILADI', style: TextStyle(color: Colors.white60, fontSize: 8 * u, letterSpacing: 1.2)),
                      Text(card.exp, style: TextStyle(color: Colors.white, fontSize: 13 * u, fontWeight: FontWeight.w700)),
                    ]),
                    SizedBox(width: 14 * u),
                    _NetBadge(card.net, u),
                  ]),
                ]),
              ),
              if (card.frozen)
                Positioned.fill(child: Container(color: const Color(0x99102030), alignment: Alignment.center, child: Text('❄  ${t('freeze').toUpperCase()}', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 3, fontSize: 15 * u)))),
            ]),
          ),
        );
      }),
    );
  }
}

class _GridDots extends CustomPainter {
  final double u;
  _GridDots(this.u);
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..color = Colors.white.withOpacity(.07);
    for (var x = 8.0; x < s.width; x += 16 * u) {
      for (var y = 8.0; y < s.height; y += 16 * u) {
        canvas.drawCircle(Offset(x, y), 1.1 * u, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridDots o) => o.u != u;
}

class _NetBadge extends StatelessWidget {
  final String net;
  final double u;
  const _NetBadge(this.net, this.u);
  @override
  Widget build(BuildContext context) {
    if (net == 'Mastercard') {
      return SizedBox(
        width: 40 * u,
        height: 26 * u,
        child: Stack(children: [
          Positioned(left: 0, child: Container(width: 26 * u, height: 26 * u, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEB001B)))),
          Positioned(right: 0, child: Container(width: 26 * u, height: 26 * u, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFF79E1B).withOpacity(.92)))),
        ]),
      );
    }
    return Text(net == 'Visa' ? 'VISA' : net.toUpperCase(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontStyle: net == 'Visa' ? FontStyle.italic : FontStyle.normal, fontSize: 15 * u, letterSpacing: 1));
  }
}

class VaultCardBack extends StatelessWidget {
  final VCard card;
  final bool revealed;
  const VaultCardBack({super.key, required this.card, this.revealed = false});
  @override
  Widget build(BuildContext context) {
    final th = kCardThemes[card.theme] ?? kCardThemes['aurora']!;
    return AspectRatio(
      aspectRatio: 1.586,
      child: LayoutBuilder(builder: (context, bc) {
        final u = bc.maxWidth / 340;
        return Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(bc.maxWidth * .06), gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: th)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(height: 22 * u),
            Container(height: 40 * u, color: Colors.black.withOpacity(.8)),
            SizedBox(height: 18 * u),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20 * u),
              child: Container(
                height: 34 * u,
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 12 * u),
                color: Colors.white.withOpacity(.9),
                child: Text(revealed ? card.cvv : '•••', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 16 * u, letterSpacing: 2)),
              ),
            ),
            const Spacer(),
            Padding(padding: EdgeInsets.fromLTRB(20 * u, 0, 20 * u, 16 * u), child: Text(t('sampleNote'), style: TextStyle(color: Colors.white70, fontSize: 10 * u))),
          ]),
        );
      }),
    );
  }
}

class VaultTab extends StatefulWidget {
  const VaultTab({super.key});
  @override
  State<VaultTab> createState() => _VaultTabState();
}

class _VaultTabState extends State<VaultTab> with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  bool _show = false;
  int _sel = 0;

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  void _toggleFlip() => _flip.isCompleted || _flip.value > .5 ? _flip.reverse() : _flip.forward();

  @override
  Widget build(BuildContext context) {
    final cards = app.profile!.cards;
    if (cards.isEmpty) return Center(child: EmptyState(t('yourCard'), t('sampleNote')));
    if (_sel >= cards.length) _sel = 0;
    final card = cards[_sel];
    final w = math.min(MediaQuery.of(context).size.width - 32, 400.0);
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
      Text(t('yourCard'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 18),
      Center(
        child: GestureDetector(
          onTap: _toggleFlip,
          child: SizedBox(
            width: w,
            child: AnimatedBuilder(
              animation: _flip,
              builder: (context, _) {
                final a = Curves.easeInOutCubic.transform(_flip.value) * math.pi;
                final back = a > math.pi / 2;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0012)
                    ..rotateY(a),
                  child: back
                      ? Transform(alignment: Alignment.center, transform: Matrix4.rotationY(math.pi), child: VaultCardBack(card: card, revealed: _show))
                      : VaultCardFace(card: card, revealed: _show),
                );
              },
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),
      Center(child: Text(t('tapFlip'), style: const TextStyle(color: C.mute, fontSize: 12))),
      if (cards.length > 1) ...[
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < cards.length; i++)
            GestureDetector(onTap: () => setState(() => _sel = i), child: Container(margin: const EdgeInsets.all(4), width: i == _sel ? 22 : 8, height: 8, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: i == _sel ? C.accent : Colors.white24))),
        ]),
      ],
      const SizedBox(height: 18),
      Row(children: [
        Expanded(child: _Act(icon: _show ? Icons.visibility_off_rounded : Icons.visibility_rounded, label: t(_show ? 'hideNo' : 'showNo'), onTap: () => setState(() => _show = !_show))),
        const SizedBox(width: 10),
        Expanded(
          child: _Act(
            icon: Icons.copy_rounded,
            label: t('copyNo'),
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: card.number));
              if (context.mounted) toast(context, t('copied'));
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Act(
            icon: card.frozen ? Icons.lock_open_rounded : Icons.ac_unit_rounded,
            label: t(card.frozen ? 'unfreeze' : 'freeze'),
            onTap: () async {
              card.frozen = !card.frozen;
              await app.saveProfile();
            },
          ),
        ),
      ]),
      const SizedBox(height: 16),
      NoteBox(t('sampleNote')),
    ]);
  }
}

class _Act extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Act({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: _glass(16),
          child: Column(children: [
            Icon(icon, color: C.accent, size: 22),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}

/* ================================== PROFILE ================================== */

/* ====================================================================== */
/*  SHELL (plan-aware navigation + "Yana" sheet) · GOALS · PLANS · PAY · PIN  */
/* ====================================================================== */
const int kPriceM = 29000, kPriceY = 290000, kPriceU = 59000, kPriceUY = 590000, kPriceB = 99000, kPriceBY = 990000, kPriceF = 79000, kPriceFY = 790000, kPriceE = 199000, kPriceEY = 1990000;
// ---- To'lov sozlamalari (Vault.html dagi bilan bir xil) ----
const String kCardNumber = '9860 1606 1902 4526';
const String kCardOwner = 'SOLIYEVA RANOHON';
const String kPromoCode = 'OLLOYOR06';
const List<String> kPayCardTypes = ['Humo', 'Uzcard', 'Visa', 'Mastercard'];
const List<Color> kGoalCols = [Color(0xFF3B5BDB), Color(0xFFFF6B6B), Color(0xFFFFB020), Color(0xFF10B981), Color(0xFF8B5CF6), Color(0xFF06B6D4)];

String sp(num n) => grp(n, 'UZS');
String planName(String p) => p == 'ultra' ? 'Ultra' : p == 'biznes' ? 'Biznes' : p == 'oila' ? 'Oila' : p == 'elite' ? 'Elite' : 'Max';
int planPrice(String p, bool y) => p == 'elite' ? (y ? kPriceEY : kPriceE) : p == 'ultra' ? (y ? kPriceUY : kPriceU) : p == 'biznes' ? (y ? kPriceBY : kPriceB) : p == 'oila' ? (y ? kPriceFY : kPriceF) : (y ? kPriceY : kPriceM);
Color planColor(String p) => p == 'ultra' ? const Color(0xFFA78BFA) : p == 'biznes' ? const Color(0xFF34D399) : p == 'oila' ? const Color(0xFFFB7185) : p == 'elite' ? C.gold : p == 'max' ? const Color(0xFFFBBF24) : C.dim;

/* ------------------------------- sections ------------------------------- */
class SecDef {
  final String k;
  final IconData icon;
  const SecDef(this.k, this.icon);
}

const List<SecDef> kSecs = [
  SecDef('home', Icons.home_rounded),
  SecDef('vault', Icons.credit_card_rounded),
  SecDef('stats', Icons.pie_chart_rounded),
  SecDef('tx', Icons.receipt_long_rounded),
  SecDef('goals', Icons.flag_rounded),
  SecDef('genesis', Icons.diamond_outlined),
  SecDef('ultra', Icons.bolt_rounded),
  SecDef('time', Icons.history_rounded),
  SecDef('biz', Icons.business_center_rounded),
  SecDef('empire', Icons.domain_rounded),
  SecDef('nexus', Icons.hub_rounded),
  SecDef('oila', Icons.family_restroom_rounded),
  SecDef('elite', Icons.workspace_premium_rounded),
  SecDef('orbit', Icons.public_rounded),
  SecDef('ehson', Icons.volunteer_activism_rounded),
  SecDef('me', Icons.person_rounded),
];

String secLabel(String k) {
  switch (k) {
    case 'home':
      return t('navHome');
    case 'vault':
      return 'Kartalar';
    case 'stats':
      return t('navStats');
    case 'tx':
      return t('navTx');
    case 'goals':
      return 'Maqsadlar';
    case 'genesis':
      return 'Genesis';
    case 'ultra':
      return 'Ultra';
    case 'time':
      return 'Vaqt';
    case 'biz':
      return 'Biznes';
    case 'empire':
      return 'Empire';
    case 'nexus':
      return 'Nexus';
    case 'oila':
      return 'Oila';
    case 'elite':
      return 'Elite';
    case 'orbit':
      return 'Orbit';
    case 'ehson':
      return 'Ehson';
    case 'plans':
      return 'Tariflar';
    default:
      return t('navMe');
  }
}

/// Mirrors navItems() in Vault.html.
List<SecDef> navItems(Profile p) {
  final el = p.isElite;
  return kSecs.where((s) {
    final k = s.k;
    if (el) return k == 'elite' || k == 'orbit' || k == 'vault' || k == 'ehson' || k == 'me';
    if (k == 'elite' || k == 'orbit') return false;
    if (k == 'biz' || k == 'empire') return p.isBiz;
    if (k == 'nexus') return p.isNexus;
    if (k == 'oila') return p.isFam;
    if (k == 'genesis') return !p.isMax;
    if (k == 'ultra' || k == 'time') return p.isUltra;
    return true;
  }).toList();
}

/// Mirrors show() gating in Vault.html.
String gateSection(Profile p, String v) {
  if ((v == 'ultra' || v == 'time') && !p.isUltra) v = 'home';
  if (p.isElite && !['elite', 'orbit', 'vault', 'ehson', 'me', 'plans'].contains(v)) v = 'elite';
  if (v == 'orbit' && !p.isElite) v = 'home';
  if (v == 'empire' && !p.isBiz) v = 'home';
  if (v == 'nexus' && !p.isNexus) v = 'home';
  if (v == 'genesis' && p.isMax) v = 'home';
  if (v == 'elite' && !p.isElite) v = 'home';
  if (v == 'biz' && !p.isBiz) v = 'home';
  if (v == 'oila' && !p.isFam) v = 'home';
  return v;
}

/// Passed to modules so they can navigate / open the plans page.
class ShellApi {
  final void Function(String) show;
  const ShellApi(this.show);
}

void upsell(BuildContext context, ShellApi api, String title, String body) {
  showDialog<void>(
    context: context,
    builder: (d) => AlertDialog(
      backgroundColor: C.bg2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: C.line)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      content: Text(body, style: const TextStyle(color: Color(0xFFA9C9BB), height: 1.5)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d), child: const Text('Keyinroq', style: TextStyle(color: C.dim))),
        TextButton(
          onPressed: () {
            Navigator.pop(d);
            api.show('plans');
          },
          child: const Text('Tariflarni ko\'rish', style: TextStyle(color: C.accent, fontWeight: FontWeight.w800)),
        ),
      ],
    ),
  );
}

class PlanChip extends StatelessWidget {
  final VoidCallback onTap;
  const PlanChip({super.key, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final p = app.profile!;
    final el = p.isElite, mx = p.isMax;
    final col = el ? C.gold : mx ? planColor(p.plan) : C.accent;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: col.withOpacity(.14), border: Border.all(color: col.withOpacity(.5))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.auto_awesome_rounded, size: 14, color: col),
          const SizedBox(width: 6),
          Text(el ? 'ELITE' : mx ? planName(p.plan) : 'Max\'ga o\'tish', style: TextStyle(color: col, fontWeight: FontWeight.w800, fontSize: 12.5)),
        ]),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  final Future<void> Function() onSignOut;
  const HomeShell({super.key, required this.onSignOut});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  String _cur = 'home';
  String _mk = monthKeyOf(DateTime.now());
  DateTime? _hiddenAt;

  late final ShellApi api = ShellApi(_show);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (app.profile!.isElite) _cur = 'elite';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (app.profile!.pin.isNotEmpty && !app.unlocked) {
        openLock(context, 'enter', onOk: () {
          app.unlocked = true;
          _startup();
        });
      } else {
        app.unlocked = true;
        _startup();
      }
    });
  }

  Future<void> _startup() async {
    await recurAuto();
    if (!mounted) return;
    remindDue(context);
    bizRemind(context);
    eRemind(context);
    tourAuto(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.paused || s == AppLifecycleState.hidden) {
      _hiddenAt = DateTime.now();
    } else if (s == AppLifecycleState.resumed) {
      final h = _hiddenAt;
      _hiddenAt = null;
      final p = app.profile;
      if (h != null && p != null && p.pin.isNotEmpty && DateTime.now().difference(h).inSeconds > 30 && mounted) {
        openLock(context, 'enter', onOk: () {});
      }
    }
  }

  void _show(String v) {
    final p = app.profile!;
    final nv = gateSection(p, v);
    setState(() => _cur = nv);
  }

  void _shift(int d) {
    final p = _mk.split('-');
    final dt = DateTime(int.parse(p[0]), int.parse(p[1]) + d, 1);
    final nk = monthKeyOf(dt);
    if (nk.compareTo(monthKeyOf(DateTime.now())) > 0) return;
    final prof = app.profile!;
    final cur = DateTime.now();
    final prev = monthKeyOf(DateTime(cur.year, cur.month - 1, 1));
    if (!prof.isMax && nk.compareTo(prev) < 0) {
      upsell(context, api, 'Cheksiz tarix Max tarifda', 'Free tarifda joriy va o\'tgan oy ko\'rinadi. Max da barcha oylar ochiq.');
      return;
    }
    setState(() => _mk = nk);
  }

  Future<void> _addTx([Tx? edit]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: C.bg2,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => TxSheet(edit: edit),
    );
  }

  Widget _body(String k) {
    switch (k) {
      case 'home':
        return HomeTab(mk: _mk, onShift: _shift, onAdd: _addTx, onSeeAll: () => _show('tx'), onPlans: () => _show('plans'));
      case 'tx':
        return TxTab(mk: _mk, onShift: _shift, onEdit: _addTx);
      case 'stats':
        return StatsTab(mk: _mk, onShift: _shift);
      case 'vault':
        return const VaultTab();
      case 'goals':
        return GoalsTab(api: api);
      case 'plans':
        return PlansTab(api: api);
      case 'me':
        return MeTab(onSignOut: widget.onSignOut, api: api);
      default:
        return buildModule(k, api);
    }
  }

  void _openMore(List<SecDef> rest) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: C.bg2,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 14),
            const Align(alignment: Alignment.centerLeft, child: Text('Boshqa bo\'limlar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.15,
              children: [
                for (final s in rest)
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.pop(c);
                      _show(s.k);
                    },
                    child: Container(
                      decoration: _glass(16),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(s.icon, color: _cur == s.k ? C.accent : C.dim),
                        const SizedBox(height: 6),
                        Text(secLabel(s.k), style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _cur == s.k ? C.accent : C.ink)),
                      ]),
                    ),
                  ),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final p = app.profile!;
        // a plan change (expiry, downgrade) may hide the current section
        final safe = gateSection(p, _cur);
        if (safe != _cur) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _cur = safe);
          });
        }
        final items = navItems(p);
        const mpri = ['elite', 'orbit', 'home', 'vault', 'stats', 'me'];
        final lim = items.length <= 5 ? items.length : 4;
        final pri = <SecDef>[];
        for (final k in mpri) {
          if (pri.length < lim) {
            final f = items.where((s) => s.k == k);
            if (f.isNotEmpty) pri.add(f.first);
          }
        }
        for (final s in items) {
          if (pri.length < lim && !pri.any((e) => e.k == s.k)) pri.add(s);
        }
        final rest = items.where((s) => !pri.any((e) => e.k == s.k)).toList();
        var sel = pri.indexWhere((s) => s.k == _cur);
        if (sel < 0) sel = rest.isNotEmpty && rest.any((s) => s.k == _cur) ? pri.length : -1;
        final showFab = _cur == 'home' || _cur == 'tx' || _cur == 'stats';
        return PopScope(
          canPop: _cur == 'home' || (p.isElite && _cur == 'elite'),
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _show(p.isElite ? 'elite' : 'home');
          },
          child: Scaffold(
            body: VaultBackdrop(
              child: SafeArea(bottom: false, child: AnimatedSwitcher(duration: const Duration(milliseconds: 260), child: KeyedSubtree(key: ValueKey(_cur), child: _body(_cur)))),
            ),
            floatingActionButton: showFab
                ? FloatingActionButton.extended(
                    onPressed: () => _addTx(),
                    backgroundColor: C.accent,
                    foregroundColor: const Color(0xFF02130D),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(t('add'), style: const TextStyle(fontWeight: FontWeight.w800)),
                  )
                : null,
            bottomNavigationBar: NavigationBarTheme(
              data: NavigationBarThemeData(
                backgroundColor: C.bg2,
                indicatorColor: C.accent.withOpacity(.16),
                labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: s.contains(WidgetState.selected) ? C.accent : C.dim)),
                iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(color: s.contains(WidgetState.selected) ? C.accent : C.dim)),
              ),
              child: NavigationBar(
                selectedIndex: sel < 0 ? 0 : sel,
                onDestinationSelected: (i) {
                  if (i < pri.length) {
                    _show(pri[i].k);
                  } else {
                    _openMore(rest);
                  }
                },
                height: 68,
                destinations: [
                  for (final s in pri) NavigationDestination(icon: Icon(s.icon), label: secLabel(s.k)),
                  if (rest.isNotEmpty) const NavigationDestination(icon: Icon(Icons.more_horiz_rounded), label: 'Yana'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/* ================================== GOALS ================================== */
int jarN(double p) => p > 0 ? math.min(30, math.max(1, (p * 30).round())) : 0;

class JarPainter extends CustomPainter {
  final double level; // 0..1 animated
  final int coins;
  final Color col;
  JarPainter(this.level, this.coins, this.col);

  static Path jar() => Path()
    ..moveTo(30, 14)
    ..lineTo(70, 14)
    ..lineTo(70, 24)
    ..cubicTo(86, 30, 90, 40, 90, 54)
    ..lineTo(90, 108)
    ..quadraticBezierTo(90, 122, 76, 122)
    ..lineTo(24, 122)
    ..quadraticBezierTo(10, 122, 10, 108)
    ..lineTo(10, 54)
    ..cubicTo(10, 40, 14, 30, 30, 24)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 128);
    final jp = jar();
    canvas.drawOval(Rect.fromCenter(center: const Offset(50, 124.5), width: 76, height: 5.6), Paint()..color = const Color(0x2E000000));
    canvas.save();
    canvas.clipPath(jp);
    // coins
    final n = coins;
    for (var k = 0; k < n; k++) {
      final r = k ~/ 5, q = k % 5;
      final x = 22.0 + q * 12.5 + (r.isOdd ? 6 : 0), y = 112.0 - r * 7;
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y + 2.5), width: 17, height: 6.8), Paint()..color = const Color(0xFFB8791A));
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 17, height: 6.8), Paint()..color = const Color(0xFFF2B134));
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 17, height: 6.8), Paint()..style = PaintingStyle.stroke..strokeWidth = .8..color = const Color(0xFFFFD36B));
    }
    // liquid level
    final top = 122 - 90 * level;
    canvas.drawRect(Rect.fromLTRB(8, top, 92, 122), Paint()..color = col.withOpacity(.3));
    canvas.drawRect(Rect.fromLTRB(8, top, 92, top + 3), Paint()..color = col.withOpacity(.55));
    canvas.restore();
    canvas.drawPath(jp, Paint()..shader = const LinearGradient(colors: [Color(0x4DFFFFFF), Color(0x0DFFFFFF), Color(0x1AFFFFFF)]).createShader(const Rect.fromLTWH(0, 0, 100, 128)));
    canvas.drawPath(jp, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..color = const Color(0x998FB3A5));
    final hl = Paint()..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round..color = const Color(0x8CFFFFFF);
    canvas.drawPath(Path()..moveTo(17, 56)..cubicTo(17, 46, 20, 38, 28, 32), hl);
    canvas.drawLine(const Offset(17, 66), const Offset(17, 96), hl..color = const Color(0x66FFFFFF));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(26, 3, 48, 11), const Radius.circular(3.5)), Paint()..color = const Color(0xFF8A93A8));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(26, 3, 48, 4), const Radius.circular(2)), Paint()..color = const Color(0x47FFFFFF));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant JarPainter o) => o.level != level || o.coins != coins || o.col != col;
}

class GoalsTab extends StatefulWidget {
  final ShellApi api;
  const GoalsTab({super.key, required this.api});
  @override
  State<GoalsTab> createState() => _GoalsTabState();
}

class _GoalsTabState extends State<GoalsTab> {
  final _n = TextEditingController(), _t = TextEditingController(), _h = TextEditingController();
  final Map<String, TextEditingController> _add = {};
  String _err = '';
  String? _sure;

  @override
  void dispose() {
    _n.dispose();
    _t.dispose();
    _h.dispose();
    for (final c in _add.values) {
      c.dispose();
    }
    super.dispose();
  }

  double _fix(double v) => kNoDec.contains(app.cur) ? v.roundToDouble() : r2(v);

  Future<void> _create() async {
    final p = app.profile!;
    if (!p.isMax && p.goals.length >= 1) {
      upsell(context, widget.api, 'Ko\'proq maqsad Max tarifda', 'Free tarifda 1 ta maqsad qo\'yish mumkin. Max da maqsadlar soni cheksiz.');
      return;
    }
    final name = _n.text.trim();
    final tg = parseAmount(_t.text);
    final hv = _h.text.trim().isEmpty ? 0.0 : parseAmount(_h.text);
    if (name.length < 2) return setState(() => _err = 'Maqsad nomini kiriting.');
    if (tg == null || tg <= 0) return setState(() => _err = 'Maqsad summasini to\'g\'ri kiriting.');
    if (hv == null || hv < 0) return setState(() => _err = 'Yig\'ilgan summa noto\'g\'ri.');
    p.goals.add(Goal(id: 'g${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}', name: name, target: _fix(tg), saved: _fix(hv)));
    _n.clear();
    _t.clear();
    _h.clear();
    setState(() => _err = '');
    await app.saveProfile();
    if (mounted) toast(context, 'Maqsad qo\'shildi');
  }

  Future<void> _addMoney(int i) async {
    final g = app.profile!.goals[i];
    final c = _add.putIfAbsent(g.id, () => TextEditingController());
    final v = parseAmount(c.text);
    if (v == null || v <= 0) {
      toast(context, 'Summani to\'g\'ri kiriting.');
      return;
    }
    g.saved = r2(g.saved + v);
    c.clear();
    await app.saveProfile();
    if (mounted) toast(context, 'Maqsadga qo\'shildi: +${grp(v)} ${curUnit()}');
  }

  @override
  Widget build(BuildContext context) {
    final p = app.profile!;
    final gs = p.goals;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
      const Text('Maqsadlar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      const Text('Katta xarid yoki jamg\'arma uchun maqsad qo\'ying va yig\'ilganini kuzating.', style: TextStyle(color: C.dim, fontSize: 13.5)),
      const SizedBox(height: 14),
      if (gs.isEmpty) Glass(child: const EmptyState('Hozircha maqsad yo\'q', 'Masalan, noutbuk yoki ta\'til uchun jamg\'arma maqsadini yarating. Pastdagi shaklda boshlang.')),
      for (var i = 0; i < gs.length; i++) _goalCard(gs[i], i),
      const SizedBox(height: 6),
      Glass(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Text('Yangi maqsad', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(width: 8),
            if (!p.isMax) Text('${gs.length} / 1', style: const TextStyle(color: C.dim, fontSize: 12.5)),
          ]),
          const SizedBox(height: 12),
          TextField(controller: _n, maxLength: 40, decoration: const InputDecoration(hintText: 'Masalan, Noutbuk', counterText: '')),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: _t, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(hintText: 'Maqsad summasi'))),
            const SizedBox(width: 10),
            Expanded(child: TextField(controller: _h, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(hintText: 'Hozir yig\'ilgan'))),
          ]),
          if (_err.isNotEmpty) ...[const SizedBox(height: 10), MsgBox(_err)],
          const SizedBox(height: 12),
          PrimaryButton(label: 'Maqsad qo\'shish', onTap: _create),
        ]),
      ),
    ]);
  }

  Widget _goalCard(Goal g, int i) {
    final pct = g.target > 0 ? math.min(1.0, g.saved / g.target) : 0.0;
    final col = kGoalCols[i % kGoalCols.length];
    final c = _add.putIfAbsent(g.id, () => TextEditingController());
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _glass(20),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 92,
          child: Column(children: [
            SizedBox(
              width: 92,
              height: 92 * 1.28,
              child: TweenAnimationBuilder<double>(
                key: ValueKey('${g.id}-${(pct * 1000).round()}'),
                tween: Tween(begin: 0, end: math.max(pct, .001)),
                duration: const Duration(milliseconds: 1100),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => CustomPaint(painter: JarPainter(v, jarN(pct), col)),
              ),
            ),
            Text('${(pct * 100).round()}%', style: TextStyle(fontWeight: FontWeight.w800, color: col)),
          ]),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(g.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 4),
            pct >= 1
                ? Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: C.accent.withOpacity(.16)), child: const Text('Maqsadga erishildi', style: TextStyle(color: C.accent, fontWeight: FontWeight.w700, fontSize: 12)))
                : Text('${grp(g.saved)} / ${grp(g.target)} ${curUnit()}', style: const TextStyle(color: C.dim, fontSize: 13)),
            const SizedBox(height: 4),
            if (pct < 1) Text('Qoldi: ${grp(g.target - g.saved)} ${curUnit()}', style: const TextStyle(color: C.mute, fontSize: 12)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: c, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(hintText: 'Summa', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)))),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: FilledButton(
                  onPressed: () => _addMoney(i),
                  style: FilledButton.styleFrom(backgroundColor: C.accent, foregroundColor: const Color(0xFF02130D), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Qo\'shish', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ]),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () async {
                if (_sure != g.id) {
                  setState(() => _sure = g.id);
                  Future<void>.delayed(const Duration(seconds: 3), () {
                    if (mounted && _sure == g.id) setState(() => _sure = null);
                  });
                  return;
                }
                app.profile!.goals.removeAt(i);
                _sure = null;
                await app.saveProfile();
                if (mounted) toast(context, 'Maqsad o\'chirildi');
              },
              child: Text(_sure == g.id ? 'Aniq o\'chiraymi?' : 'Maqsadni o\'chirish', style: const TextStyle(color: C.out, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ]),
        ),
      ]),
    );
  }
}

/* ================================== PLANS ================================== */
bool planIncludes(String owned, String card) {
  if (owned == card) return true;
  const inc = {
    'max': ['ultra', 'biznes', 'oila', 'elite'],
    'ultra': ['oila'],
    'biznes': ['elite'],
  };
  return (inc[card] ?? const []).contains(owned);
}

class PlansTab extends StatefulWidget {
  final ShellApi api;
  const PlansTab({super.key, required this.api});
  @override
  State<PlansTab> createState() => _PlansTabState();
}

class _PlansTabState extends State<PlansTab> {
  bool _y = false;
  bool _sureFree = false;

  Widget _plan(String id, String title, String tag, String desc, List<String> feats, {bool free = false}) {
    final p = app.profile!;
    final col = planColor(id);
    final mx = p.isMax;
    final cur = !free && p.plan == id && mx;
    final inside = !free && !cur && mx && planIncludes(p.plan, id);
    final price = free ? 0 : planPrice(id, _y);
    Widget btn;
    if (free) {
      btn = mx
          ? OutlinedButton(
              onPressed: () async {
                if (!_sureFree) {
                  setState(() => _sureFree = true);
                  Future<void>.delayed(const Duration(seconds: 3), () {
                    if (mounted) setState(() => _sureFree = false);
                  });
                  return;
                }
                p.plan = kFree;
                p.maxUntil = 0;
                await app.saveProfile();
                if (mounted) toast(context, 'Free tarifga qaytdingiz');
              },
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), side: const BorderSide(color: C.line), foregroundColor: C.ink),
              child: Text(_sureFree ? 'Aniq? Yana bosing' : 'Free ga qaytish'),
            )
          : const OutlinedButton(onPressed: null, child: Text('Joriy tarif'));
    } else if (cur) {
      btn = FilledButton(onPressed: null, child: Text('Joriy tarif · ${p.daysLeft} kun qoldi'));
    } else if (inside) {
      btn = FilledButton(onPressed: null, child: Text('${planName(p.plan)} ichida'));
    } else {
      btn = PrimaryButton(
        label: '${title}ni yoqish',
        onTap: () async {
          final ok = await openPay(context, id, _y);
          if (ok == true) {
            if (app.profile!.isElite) widget.api.show('elite');
          }
        },
      );
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0x0DFFFFFF),
        border: Border.all(color: free ? C.line : col.withOpacity(.55), width: free ? 1 : 1.4),
        boxShadow: free ? null : [BoxShadow(color: col.withOpacity(.12), blurRadius: 30, spreadRadius: -8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (tag.isNotEmpty) Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: col.withOpacity(.16)), child: Text(tag, style: TextStyle(color: col, fontWeight: FontWeight.w800, fontSize: 11.5))),
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(sp(price), style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: free ? C.ink : col)),
          const SizedBox(width: 6),
          Padding(padding: const EdgeInsets.only(bottom: 5), child: Text(free ? 'so\'m' : 'so\'m / ${_y ? 'yil' : 'oy'}', style: const TextStyle(color: C.dim, fontSize: 13))),
        ]),
        const SizedBox(height: 4),
        Text(!free && _y ? 'Oyiga taxminan ${sp((price / 12).round())} so\'m. 2 oy bepul.' : desc, style: const TextStyle(color: C.dim, fontSize: 13)),
        const SizedBox(height: 12),
        ...feats.map((f) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.check_rounded, size: 18, color: free ? C.accent : col), const SizedBox(width: 8), Expanded(child: Text(f, style: const TextStyle(fontSize: 13.5, height: 1.35)))]))),
        if (free) ...kPlanFree.where((f) => !f.$2).map((f) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [const Icon(Icons.remove_rounded, size: 18, color: C.mute), const SizedBox(width: 8), Expanded(child: Text(f.$1, style: const TextStyle(fontSize: 13.5, color: C.mute)))]))),
        const SizedBox(height: 14),
        SizedBox(width: double.infinity, child: btn),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
      const Text('Tariflar', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      const Text('Free bilan boshlang, ko\'proq tahlil kerak bo\'lsa Max ga o\'ting.', style: TextStyle(color: C.dim, fontSize: 13.5)),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _SegBtn(label: 'Oylik', on: !_y, onTap: () => setState(() => _y = false))),
        const SizedBox(width: 8),
        Expanded(child: _SegBtn(label: 'Yillik · 2 oy bepul', on: _y, onTap: () => setState(() => _y = true))),
      ]),
      const SizedBox(height: 16),
      _plan('free', 'Free', '', 'Kundalik hisob uchun yetarli asosiy imkoniyatlar.', kPlanFree.where((f) => f.$2).map((f) => f.$1).toList(), free: true),
      _plan('max', 'Max', 'Barcha funksiyalar', 'Hamma imkoniyat, cheklovsiz.', kPlanMax),
      _plan('ultra', 'Ultra', 'Eng to\'liq', 'Max + moliyaviy boshqaruv vositalari.', kPlanUltra),
      _plan('biznes', 'Biznes', 'Kichik biznes uchun', 'Max + biznes hisobi va hisob-faktura.', kPlanBiz),
      _plan('oila', 'Oila', '5 kishigacha', 'Ultra + umumiy oilaviy byudjet.', kPlanFam),
      _plan('elite', 'Elite', 'Boshqaruv darajasi', 'Hisob yuritish emas, biznesni boshqarish uchun.', kPlanElite),
      const NoteBox('Max, Ultra, Biznes, Oila yoki Elite ni yoqish uchun «To\'lash» orqali karta bilan to\'lang yoki promokod kiriting.'),
    ]);
  }
}

/// Returns true when a plan was activated. Mirrors the web payment modal (card details + screenshot, or promo code).
Future<bool?> openPay(BuildContext context, String plan, bool yearly) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: C.bg2,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (c) => PaySheet(plan: plan, yearly: yearly),
  );
}

class PaySheet extends StatefulWidget {
  final String plan;
  final bool yearly;
  const PaySheet({super.key, required this.plan, required this.yearly});
  @override
  State<PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends State<PaySheet> {
  int _step = 0;
  String _type = '';
  Uint8List? _img;
  final _code = TextEditingController();
  String _err = '';

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _activate(String method) async {
    final p = app.profile!;
    p.plan = widget.plan;
    p.maxUntil = DateTime.now().add(Duration(days: widget.yearly ? 365 : 30)).millisecondsSinceEpoch;
    p.billing = widget.yearly ? 'y' : 'm';
    p.payMethod = method;
    await app.saveProfile();
    if (!mounted) return;
    final name = planName(widget.plan);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    nav.pop(true);
    messenger.showSnackBar(SnackBar(content: Text('$name yoqildi!')));
  }

  Future<void> _pick() async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 1400);
      if (x == null) return;
      final b = await x.readAsBytes();
      setState(() {
        _img = b;
        _err = '';
      });
    } catch (_) {
      setState(() => _err = 'Rasmni tanlab bo\'lmadi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = planName(widget.plan);
    final price = planPrice(widget.plan, widget.yearly);
    final col = planColor(widget.plan);
    Widget body;
    if (_step == 0) {
      body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('$name: ${sp(price)} so\'m / ${widget.yearly ? 'yil' : 'oy'}', style: const TextStyle(color: C.dim)),
        const SizedBox(height: 16),
        PrimaryButton(label: 'To\'lash', onTap: () => setState(() => _step = 1)),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: () => setState(() => _step = 3), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), side: const BorderSide(color: C.line), foregroundColor: C.ink), child: const Text('Promokod')),
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Yopish', style: TextStyle(color: C.dim))),
      ]);
    } else if (_step == 1) {
      body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Karta turini tanlang:', style: TextStyle(color: C.dim)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.6,
          children: [
            for (final k in kPayCardTypes)
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => setState(() {
                  _type = k;
                  _step = 2;
                }),
                child: Container(alignment: Alignment.center, decoration: _glass(14), child: Text(k, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
              ),
          ],
        ),
        TextButton(onPressed: () => setState(() => _step = 0), child: const Text('Orqaga', style: TextStyle(color: C.dim))),
      ]);
    } else if (_step == 2) {
      body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: const LinearGradient(colors: [Color(0xFF064E3B), Color(0xFF0F2A22)]), border: Border.all(color: C.line)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$_type karta', style: const TextStyle(color: C.dim, fontSize: 12.5)),
            const SizedBox(height: 8),
            Text(kCardNumber, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 2)),
            const SizedBox(height: 6),
            Text(kCardOwner, style: const TextStyle(color: C.dim, letterSpacing: 1)),
            const SizedBox(height: 8),
            Text('${sp(price)} so\'m', style: TextStyle(fontWeight: FontWeight.w800, color: col, fontSize: 18)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: kCardNumber.replaceAll(' ', '')));
                if (context.mounted) toast(context, 'Karta raqami nusxalandi');
              },
              icon: const Icon(Icons.copy_rounded, size: 16, color: C.accent),
              label: const Text('Raqamni nusxalash', style: TextStyle(color: C.accent)),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        const Text('Shu kartaga to\'lovni amalga oshiring, so\'ng to\'lov skrinshotini yuklang.', style: TextStyle(color: C.dim, fontSize: 13)),
        const SizedBox(height: 10),
        if (_img != null) ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.memory(_img!, height: 160, fit: BoxFit.cover)),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: _pick, icon: const Icon(Icons.upload_rounded), label: Text(_img == null ? 'Skrinshot yuklash' : 'Boshqa skrinshot tanlash'), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), side: const BorderSide(color: C.line), foregroundColor: C.ink)),
        if (_err.isNotEmpty) ...[const SizedBox(height: 10), MsgBox(_err)],
        const SizedBox(height: 12),
        PrimaryButton(label: 'Tasdiqlash', onTap: _img == null ? null : () => _activate(_type)),
        TextButton(onPressed: () => setState(() => _step = 1), child: const Text('Orqaga', style: TextStyle(color: C.dim))),
      ]);
    } else {
      body = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: _code, autofocus: true, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(hintText: 'Promokodni kiriting')),
        if (_err.isNotEmpty) ...[const SizedBox(height: 10), MsgBox(_err)],
        const SizedBox(height: 14),
        PrimaryButton(
          label: 'Tasdiqlash',
          onTap: () {
            final v = _code.text.trim().toUpperCase();
            if (v != kPromoCode) {
              setState(() => _err = v.isEmpty ? 'Promokodni kiriting.' : 'Promokod noto\'g\'ri.');
              return;
            }
            _activate('promo');
          },
        ),
        TextButton(onPressed: () => setState(() => _step = 0), child: const Text('Orqaga', style: TextStyle(color: C.dim))),
      ]);
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 14),
          Align(alignment: Alignment.centerLeft, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: col.withOpacity(.16)), child: Text(name, style: TextStyle(color: col, fontWeight: FontWeight.w800, fontSize: 12)))),
          const SizedBox(height: 8),
          Text('$name tarifni yoqish', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          body,
        ]),
      ),
    );
  }
}

/* =================================== PIN =================================== */
String hashPin(String x) => sha256.convert(utf8.encode('hmy:$x')).toString();

/// mode: 'enter' (lock the app), 'verify' (confirm current PIN), 'set' (create a new PIN)
Future<void> openLock(BuildContext context, String mode, {required VoidCallback onOk}) {
  return Navigator.of(context).push(MaterialPageRoute<void>(fullscreenDialog: true, builder: (c) => LockScreen(mode: mode, onOk: onOk)));
}

class LockScreen extends StatefulWidget {
  final String mode;
  final VoidCallback onOk;
  const LockScreen({super.key, required this.mode, required this.onOk});
  @override
  State<LockScreen> createState() => _LockState();
}

class _LockState extends State<LockScreen> {
  String _buf = '', _tmp = '', _msg = '';
  late String _m = widget.mode == 'set' ? 'set1' : widget.mode;
  int _tries = 0;
  DateTime _until = DateTime.fromMillisecondsSinceEpoch(0);

  String get _title => _m == 'set1' ? 'Yangi PIN kod o\'rnating' : _m == 'set2' ? 'PIN kodni qayta kiriting' : _m == 'verify' ? 'Joriy PIN kodni kiriting' : 'PIN kodni kiriting';

  Future<void> _tap(String d) async {
    if (_buf.length >= 5) return;
    final w = _until.difference(DateTime.now()).inSeconds;
    if (w > 0) {
      setState(() => _msg = 'Juda ko\'p urinish. $w soniyadan keyin urinib ko\'ring.');
      return;
    }
    setState(() {
      _buf += d;
      _msg = '';
    });
    if (_buf.length < 5) return;
    HapticFeedback.selectionClick();
    final h = hashPin(_buf);
    final p = app.profile!;
    if (_m == 'enter' || _m == 'verify') {
      if (h == p.pin) {
        final cb = widget.onOk;
        if (mounted) Navigator.of(context).pop();
        cb();
        return;
      }
      _tries++;
      if (_tries >= 5) {
        _tries = 0;
        _until = DateTime.now().add(const Duration(seconds: 30));
      }
      setState(() {
        _buf = '';
        _msg = 'PIN noto\'g\'ri.';
      });
      HapticFeedback.heavyImpact();
    } else if (_m == 'set1') {
      setState(() {
        _tmp = _buf;
        _buf = '';
        _m = 'set2';
      });
    } else {
      if (_buf == _tmp) {
        p.pin = h;
        await app.saveProfile();
        app.unlocked = true;
        final cb = widget.onOk;
        if (mounted) Navigator.of(context).pop();
        cb();
      } else {
        setState(() {
          _buf = '';
          _tmp = '';
          _m = 'set1';
          _msg = 'PIN mos kelmadi. Qaytadan kiriting.';
        });
      }
    }
  }

  Future<void> _forgot() async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: C.bg2,
        title: const Text('PINni o\'chirish', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Tasdiqlash uchun hisob nomini (ismingizni) kiriting.', style: TextStyle(color: C.dim, fontSize: 13)),
          const SizedBox(height: 10),
          TextField(controller: c, decoration: const InputDecoration(hintText: 'Ism')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Bekor', style: TextStyle(color: C.dim))),
          TextButton(onPressed: () => Navigator.pop(d, c.text.trim().toLowerCase() == app.profile!.name.toLowerCase()), child: const Text('O\'chirish', style: TextStyle(color: C.out, fontWeight: FontWeight.w800))),
        ],
      ),
    );
    c.dispose();
    if (ok == true) {
      app.profile!.pin = '';
      await app.saveProfile();
      app.unlocked = true;
      final cb = widget.onOk;
      if (mounted) Navigator.of(context).pop();
      cb();
    } else if (ok == false && mounted) {
      setState(() => _msg = 'Hisob nomi noto\'g\'ri.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final canLeave = widget.mode != 'enter';
    return PopScope(
      canPop: canLeave,
      child: Scaffold(
        body: VaultBackdrop(
          child: SafeArea(
            child: Column(children: [
              if (canLeave) Align(alignment: Alignment.centerLeft, child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded))) else const SizedBox(height: 48),
              const Spacer(),
              const VaultLogo(size: 54),
              const SizedBox(height: 18),
              Text(_title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 18),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                for (var i = 0; i < 5; i++) AnimatedContainer(duration: const Duration(milliseconds: 150), margin: const EdgeInsets.all(7), width: 14, height: 14, decoration: BoxDecoration(shape: BoxShape.circle, color: i < _buf.length ? C.accent : Colors.transparent, border: Border.all(color: i < _buf.length ? C.accent : C.mute, width: 1.5))),
              ]),
              SizedBox(height: 40, child: Center(child: Text(_msg, style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13.5)))),
              SizedBox(
                width: 300,
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    for (final d in ['1', '2', '3', '4', '5', '6', '7', '8', '9'])
                      _Key(label: d, onTap: () => _tap(d)),
                    const SizedBox(),
                    _Key(label: '0', onTap: () => _tap('0')),
                    _Key(icon: Icons.backspace_outlined, onTap: () => setState(() => _buf = _buf.isEmpty ? '' : _buf.substring(0, _buf.length - 1))),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (_m == 'enter') LinkText('PIN esdan chiqdimi?', _forgot),
              const Spacer(),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Key extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  const _Key({this.label, this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: onTap,
        child: Container(alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(40), color: const Color(0x0DFFFFFF), border: Border.all(color: C.line)), child: icon != null ? Icon(icon, color: C.dim) : Text(label!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600))),
      );
}

class PinTile extends StatelessWidget {
  const PinTile({super.key});
  @override
  Widget build(BuildContext context) {
    final p = app.profile!;
    final on = p.pin.isNotEmpty;
    return Glass(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.lock_rounded, color: C.accent),
        title: const Text('PIN kod'),
        subtitle: Text(on ? 'Yoqilgan. 30 soniyadan ko\'p tark etsangiz qulflanadi.' : 'O\'chiq. 5 raqamli PIN bilan himoyalang.', style: const TextStyle(color: C.dim, fontSize: 12.5)),
        trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: (on ? C.accent : C.mute).withOpacity(.16)), child: Text(on ? 'Yoqilgan' : 'O\'chiq', style: TextStyle(color: on ? C.accent : C.dim, fontWeight: FontWeight.w700, fontSize: 12))),
        onTap: () {
          if (!on) {
            openLock(context, 'set', onOk: () {
              if (context.mounted) toast(context, 'PIN kod o\'rnatildi 🔒');
            });
            return;
          }
          showModalBottomSheet<void>(
            context: context,
            backgroundColor: C.bg2,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            builder: (c) => SafeArea(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                ListTile(
                  leading: const Icon(Icons.edit_rounded, color: C.accent),
                  title: const Text('PINni o\'zgartirish'),
                  onTap: () {
                    Navigator.pop(c);
                    openLock(context, 'verify', onOk: () => openLock(context, 'set', onOk: () {}));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.lock_open_rounded, color: C.out),
                  title: const Text('PINni o\'chirish', style: TextStyle(color: C.out)),
                  onTap: () {
                    Navigator.pop(c);
                    openLock(context, 'verify', onOk: () async {
                      app.profile!.pin = '';
                      await app.saveProfile();
                      if (context.mounted) toast(context, 'PIN o\'chirildi');
                    });
                  },
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}

/* ====================================================================== */
/*  ULTRA: wallets · recurring · debts · budget · report · net worth ·     */
/*         memory · daily budget · where-did-money-go · missions · backup  */
/* ====================================================================== */
const List<String> kWalletTypes = ['Naqd', 'Humo', 'Uzcard', 'Visa', 'Mastercard', "Jamg'arma"];
const Map<String, List<Object>> kThemes = {
  'blue': [Color(0xFF3B5BDB), "Ko'k"],
  'green': [Color(0xFF0C8F61), 'Yashil'],
  'violet': [Color(0xFF7C3AED), 'Binafsha'],
  'rose': [Color(0xFFE11D48), 'Qizil'],
  'teal': [Color(0xFF0D9488), 'Firuza'],
};

String mny(num n) => '${sp(n.round())} ${curUnit()}';
String mlab(String k) => '${monthName(int.parse(k.substring(5, 7)))} ${k.substring(0, 4)}';
String pad2(int n) => two(n);
String nid() => DateTime.now().millisecondsSinceEpoch.toRadixString(36) + math.Random().nextInt(46656).toRadixString(36);
double fixAmt(double v) => kNoDec.contains(app.cur) ? v.roundToDouble() : r2(v);

DateTime parseDay(String d) {
  final p = d.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

int daysTo(int day) {
  final n = DateTime.now();
  final base = DateTime(n.year, n.month, n.day);
  DateTime at(int y, int m) => DateTime(y, m, math.min(day, DateTime(y, m + 1, 0).day));
  var c = at(n.year, n.month);
  if (c.isBefore(base)) c = at(n.year, n.month + 1);
  return c.difference(base).inDays;
}

int dueIn(String d) {
  final n = DateTime.now();
  return parseDay(d).difference(DateTime(n.year, n.month, n.day)).inDays;
}

String prevMonthKey(String mk) {
  final p = mk.split('-');
  return monthKeyOf(DateTime(int.parse(p[0]), int.parse(p[1]) - 1, 1));
}

/* ---- Free/Max side effects shared across the app ---- */
void limitCheck(BuildContext context) {
  final p = app.profile;
  if (p == null || p.x['nOff'] == true || !(p.limit > 0)) return;
  final key = monthKeyOf(DateTime.now());
  var spent = 0.0;
  for (final x in app.listOf(key)) {
    if (x.t == 'out') spent += x.a;
  }
  final lv = spent >= p.limit ? 2 : spent >= p.limit * .8 ? 1 : 0;
  final wn = p.mp('wn');
  if (lv > ((wn[key] ?? 0) as num)) {
    wn[key] = lv;
    app.saveProfile();
    toast(context, lv == 2 ? '🚨 Oylik limitdan oshdingiz!' : '⚠️ Oylik limitning 80% sarflandi');
  }
}

/// Mirrors recurAuto(): books recurring payments that fell due this month.
Future<int> recurAuto() async {
  final p = app.profile;
  if (p == null || !p.isUltra) return 0;
  final now = DateTime.now();
  final key = monthKeyOf(now);
  var n = 0;
  final list = p.lst('recur');
  for (var i = 0; i < list.length; i++) {
    final r = list[i];
    final dim = DateTime(now.year, now.month + 1, 0).day;
    final dd = math.min(((r['day'] ?? 1) as num).toInt(), dim);
    if (r['last'] == key || now.day < dd) continue;
    await app.addTx(Tx(id: newId(), t: 'out', a: fixAmt(((r['amt'] ?? 0) as num).toDouble()), c: '${r['cat'] ?? 'other'}', n: '${r['name']} (avto)', d: '$key-${two(dd)}', ts: now.millisecondsSinceEpoch + i, ex: {'src': 'auto'}));
    r['last'] = key;
    n++;
  }
  if (n > 0) await app.saveProfile();
  return n;
}

void remindDue(BuildContext context) {
  final p = app.profile;
  if (p == null || !p.isUltra || p.x['nOff'] == true) return;
  final m = <String>[];
  for (final r in p.lst('recur')) {
    final d = daysTo(((r['day'] ?? 1) as num).toInt());
    if (d <= 3) m.add('${r['name']}${d > 0 ? ' ($d kun)' : ' (bugun)'}');
  }
  for (final x in p.lst('debts')) {
    final due = '${x['due'] ?? ''}';
    if (due.isNotEmpty) {
      final d = dueIn(due);
      if (d <= 3) m.add('${x['who']}${d < 0 ? " (muddati o'tgan)" : d > 0 ? ' ($d kun)' : ' (bugun)'}');
    }
  }
  if (m.isNotEmpty) toast(context, 'Eslatma: ${m.take(3).join(', ')}');
}

/* ----------------------------- missions ----------------------------- */
class Mission {
  final String id, t, d;
  final int pts;
  const Mission(this.id, this.t, this.d, this.pts);
}

const List<Mission> kMissions = [
  Mission('m7', '7 kun keraksiz xarajatlarsiz', "7 kun Ko'ngil ochar, Kiyim va Boshqa kategoriyalarida chiqim bo'lmasin.", 100),
  Mission('m100', "Birinchi 100 000 so'mni yig'ish", "Maqsadlar va jamg'arma hamyonlaridagi jami summa 100 000 so'mga yetsin.", 150),
  Mission('m5', '5 kun ketma-ket hisob yuritish', '5 kun ketma-ket kamida bittadan operatsiya yozing.', 50),
];

double misTarget() => app.cur == 'UZS' ? 100000 : (100000 * ((kCurd[app.cur]![1] as num).toDouble() / 12000)).roundToDouble();
String misT(Mission m) => m.id == 'm100' && app.cur != 'UZS' ? "Birinchi ${mny(misTarget())} yig'ish" : m.t;
String misD(Mission m) => m.id == 'm100' && app.cur != 'UZS' ? "Maqsadlar va jamg'arma hamyonlaridagi jami summa ${mny(misTarget())} ga yetsin." : m.d;
String dAdd(String d, int n) => dayKey(parseDay(d).add(Duration(days: n)));

({String s, double p, String x}) misState(String id) {
  final p = app.profile!;
  final r = p.mp('missions')[id];
  final today = todayStr();
  if (r == null) return (s: 'idle', p: 0, x: '');
  if ('${r['done']}'.isNotEmpty && r['done'] != null) return (s: 'done', p: 1, x: 'Bajarildi: ${r['done']}');
  final start = '${r['start']}';
  final ds = parseDay(today).difference(parseDay(start)).inDays;
  if (id == 'm7') {
    final end = dAdd(start, 6);
    final bad = app.txs.any((x) => x.t == 'out' && x.d.compareTo(start) >= 0 && x.d.compareTo(end) <= 0 && ['fun', 'cloth', 'other'].contains(x.c));
    if (bad) return (s: 'fail', p: math.min(ds, 7) / 7, x: 'Keraksiz xarajat qayd etildi. Qaytadan boshlang.');
    if (ds >= 7) return (s: 'win', p: 1, x: '');
    return (s: 'run', p: ds / 7, x: "$ds / 7 kun o'tdi");
  }
  if (id == 'm100') {
    var tot = 0.0;
    final tg = misTarget();
    for (final g in p.goals) {
      tot += g.saved;
    }
    for (final w in p.lst('wallets')) {
      if (w['type'] == "Jamg'arma") tot += ((w['bal'] ?? 0) as num).toDouble();
    }
    if (tot >= tg) return (s: 'win', p: 1, x: '');
    return (s: 'run', p: math.max(0, tot) / tg, x: '${mny(math.max(0, tot))} / ${mny(tg)}');
  }
  final has = <String>{};
  for (final x in app.txs) {
    if (x.d.compareTo(start) >= 0) has.add(x.d);
  }
  var best = 0, run = 0;
  for (var k = 0; k <= ds; k++) {
    if (has.contains(dAdd(start, k))) {
      run++;
      if (run > best) best = run;
    } else {
      run = 0;
    }
  }
  if (best >= 5) return (s: 'win', p: 1, x: '');
  return (s: 'run', p: best / 5, x: 'Eng uzun seriya: $best / 5 kun');
}

String evalMissions() {
  final p = app.profile;
  if (p == null || !p.isUltra) return '';
  String msg = '';
  var ch = false;
  final ms = p.mp('missions');
  for (final m in kMissions) {
    final r = ms[m.id];
    if (r != null && ('${r['done']}'.isEmpty || r['done'] == null) && misState(m.id).s == 'win') {
      r['done'] = todayStr();
      p.x['olam'] = ((p.x['olam'] ?? 0) as num).toInt() + m.pts;
      ch = true;
      msg = '🏆 Missiya bajarildi: ${misT(m)} (+${m.pts} Olam)';
    }
  }
  if (ch) app.saveProfile();
  return msg;
}

/* ------------------------------- net worth ------------------------------- */
({double cash, double card, double sav, double debt, double recv, double net}) nwCalc() {
  final p = app.profile!;
  double cash = 0, card = 0, sav = 0, debt = 0, recv = 0;
  for (final w in p.lst('wallets')) {
    final b = ((w['bal'] ?? 0) as num).toDouble();
    if (w['type'] == 'Naqd') {
      cash += b;
    } else if (w['type'] == "Jamg'arma") {
      sav += b;
    } else {
      card += b;
    }
  }
  for (final d in p.lst('debts')) {
    final a = ((d['amt'] ?? 0) as num).toDouble();
    if (d['dir'] == 'out') {
      debt += a;
    } else {
      recv += a;
    }
  }
  return (cash: cash, card: card, sav: sav, debt: debt, recv: recv, net: r2(cash + card + sav - debt));
}

Map<String, dynamic> memSnap(String k) {
  final p = app.profile!;
  final s = app.sums(k);
  final bo = app.byCat(k, 'out');
  String? tc;
  var tv = 0.0;
  for (final c in catsOf('out')) {
    if ((bo[c.id] ?? 0) > tv) {
      tv = bo[c.id]!;
      tc = c.name;
    }
  }
  final outs = app.listOf(k).where((x) => x.t == 'out').toList()..sort((a, b) => b.a.compareTo(a.a));
  return {'i': s.i, 'o': s.o, 'tc': tc, 'tt': outs.isEmpty ? 0 : outs.first.a, 'nw': p.mp('nw')[k], 'g': p.goals.map((g) => [g.name, g.target > 0 ? (math.min(1.0, g.saved / g.target) * 100).round() : 0]).toList()};
}

/* ------------------------------ UI helpers ------------------------------ */
class URow extends StatelessWidget {
  final String title;
  final String? sub;
  final String? amount;
  final Color? amountColor;
  final bool late;
  final Widget? action;
  const URow({super.key, required this.title, this.sub, this.amount, this.amountColor, this.late = false, this.action});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: late ? C.out.withOpacity(.08) : const Color(0x08FFFFFF), border: Border.all(color: late ? C.out.withOpacity(.4) : C.line)),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
              if (sub != null && sub!.isNotEmpty) Text(sub!, style: const TextStyle(color: C.dim, fontSize: 12.5)),
            ]),
          ),
          if (amount != null) Padding(padding: const EdgeInsets.only(left: 8), child: Text(amount!, textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: amountColor ?? C.ink))),
          if (action != null) action!,
        ]),
      );
}

/// Two-step destructive button ("O'chirish" -> "Aniq?").
class SureBtn extends StatefulWidget {
  final String label;
  final VoidCallback onSure;
  const SureBtn({super.key, this.label = "O'chirish", required this.onSure});
  @override
  State<SureBtn> createState() => _SureBtnState();
}

class _SureBtnState extends State<SureBtn> {
  bool _s = false;
  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: () {
          if (!_s) {
            setState(() => _s = true);
            Future<void>.delayed(const Duration(seconds: 3), () {
              if (mounted) setState(() => _s = false);
            });
            return;
          }
          widget.onSure();
        },
        style: TextButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
        child: Text(_s ? 'Aniq?' : widget.label, style: const TextStyle(color: C.out, fontWeight: FontWeight.w700, fontSize: 12.5)),
      );
}

Widget uField(TextEditingController c, String hint, {bool num = false, int? max, TextInputType? kt, ValueChanged<String>? onChanged}) => TextField(
      controller: c,
      maxLength: max,
      onChanged: onChanged,
      keyboardType: kt ?? (num ? const TextInputType.numberWithOptions(decimal: true) : null),
      decoration: InputDecoration(hintText: hint, counterText: '', isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
    );

Widget uCard(String title, {String? sub, required List<Widget> children}) => Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _glass(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          if (sub != null) Expanded(child: Padding(padding: const EdgeInsets.only(left: 8), child: Text(sub, textAlign: TextAlign.right, style: const TextStyle(color: C.dim, fontSize: 12.5)))),
        ]),
        const SizedBox(height: 12),
        ...children,
      ]),
    );

Widget uSmall(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t, style: const TextStyle(color: C.dim, fontSize: 12.5, height: 1.4)));
Widget uBtn(String label, VoidCallback f, {bool ghost = false}) => SizedBox(
      height: 46,
      child: ghost
          ? OutlinedButton(onPressed: f, style: OutlinedButton.styleFrom(side: const BorderSide(color: C.line), foregroundColor: C.ink, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)))
          : FilledButton(onPressed: f, style: FilledButton.styleFrom(backgroundColor: C.accent, foregroundColor: const Color(0xFF02130D), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))),
    );
Widget uBar(double pct, Color col) => ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: pct.clamp(0.0, 1.0), minHeight: 6, backgroundColor: Colors.white.withOpacity(.08), valueColor: AlwaysStoppedAnimation(col)));

/* ================================= ULTRA TAB ================================= */
class UltraTab extends StatefulWidget {
  final ShellApi api;
  const UltraTab({super.key, required this.api});
  @override
  State<UltraTab> createState() => _UltraTabState();
}

class _UltraTabState extends State<UltraTab> {
  int _tab = 0;
  String get mk => monthKeyOf(DateTime.now());
  static const _groups = ['Hamyon', "To'lovlar", 'Reja', 'Aqlli', 'Missiyalar', 'Sozlama'];

  // controllers
  final wn = TextEditingController(), wc = TextEditingController(), wb = TextEditingController();
  String wt = kWalletTypes.first;
  final tfA = TextEditingController();
  String tfF = '', tfT = '';
  final rn = TextEditingController(), ra = TextEditingController(), rd = TextEditingController();
  String rc = 'food';
  final dw = TextEditingController(), da = TextEditingController(), de = TextEditingController();
  String dr = 'in';
  final Map<String, TextEditingController> bud = {};
  final memo = TextEditingController();
  final bk = TextEditingController();
  // manual receipt
  final sa = TextEditingController(), sn = TextEditingController();
  String sd = todayStr(), sc = 'food', sw = '';

  Profile get p => app.profile!;

  void _msg(String m) => toast(context, m);
  Future<void> _done([String? m]) async {
    await app.saveProfile();
    if (mounted && m != null) _msg(m);
  }

  @override
  void initState() {
    super.initState();
    final m = evalMissions();
    if (m.isNotEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => _msg(m));
  }

  @override
  void dispose() {
    for (final c in [wn, wc, wb, tfA, rn, ra, rd, dw, da, de, memo, bk, sa, sn]) {
      c.dispose();
    }
    for (final c in bud.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!p.isUltra) {
      return ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Ultra', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Bir nechta hamyon va karta, takroriy to\'lovlar, qarz daftari, byudjet rejasi, PDF hisobot, chek skaneri, sof boylik, moliyaviy xotira, kunlik byudjet, missiyalar, zaxira va mavzular.', style: TextStyle(color: C.dim)),
        const SizedBox(height: 16),
        PrimaryButton(label: 'Ultra ga o\'tish', onTap: () => widget.api.show('plans')),
      ]);
    }
    // auto-snapshots (net worth of this month, frozen memory of finished months)
    final nwv = nwCalc();
    final ck = monthKeyOf(DateTime.now());
    if (p.mp('nw')[ck] != nwv.net) {
      p.mp('nw')[ck] = nwv.net;
      app.saveProfile();
    }
    var fz = false;
    final keys = <String>{for (final x in app.txs) x.d.substring(0, 7)};
    for (final k in keys) {
      if (k.compareTo(ck) < 0 && p.mp('mem')[k] == null) {
        p.mp('mem')[k] = memSnap(k);
        fz = true;
      }
    }
    if (fz) app.saveProfile();

    final groups = <List<Widget>>[
      [_wallets(), _netWorth(nwv)],
      [_recur(), _debts()],
      [_budget(), _report(nwv), _memory(nwv, keys)],
      [_daily(), _where(), _receipt()],
      [_missions()],
      [_backup(), _theme()],
    ];
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
      const Text('Ultra', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      const Text('Moliyaviy boshqaruv vositalari.', style: TextStyle(color: C.dim, fontSize: 13.5)),
      const SizedBox(height: 12),
      SizedBox(
        height: 40,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (var i = 0; i < _groups.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_groups[i]),
                selected: _tab == i,
                onSelected: (_) => setState(() => _tab = i),
                selectedColor: C.accent.withOpacity(.2),
                backgroundColor: const Color(0x0AFFFFFF),
                side: BorderSide(color: _tab == i ? C.accent : C.line),
                labelStyle: TextStyle(color: _tab == i ? Colors.white : C.dim, fontWeight: FontWeight.w700),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 14),
      ...groups[_tab],
    ]);
  }

  /* ---- wallets + transfer ---- */
  Widget _wallets() {
    final w = p.lst('wallets');
    var tot = 0.0;
    for (final x in w) {
      tot += ((x['bal'] ?? 0) as num).toDouble();
    }
    if (tfF.isEmpty || !w.any((x) => x['id'] == tfF)) tfF = w.isNotEmpty ? '${w.first['id']}' : '';
    if (tfT.isEmpty || !w.any((x) => x['id'] == tfT)) tfT = w.length > 1 ? '${w[1]['id']}' : '';
    return uCard('Hamyonlar va kartalar', sub: 'Jami: ${mny(tot)}', children: [
      if (w.isEmpty) uSmall('Hali hamyon yo\'q. Naqd, karta yoki jamg\'arma qo\'shing.'),
      for (final x in w) URow(title: '${x['name']}', sub: '${x['type']}${('${x['last4'] ?? ''}').isNotEmpty ? ' •••• ${x['last4']}' : ''}', amount: mny((x['bal'] ?? 0) as num), action: SureBtn(onSure: () {
        p.x['wallets'] = w.where((y) => y['id'] != x['id']).toList();
        _done();
      })),
      const SizedBox(height: 4),
      Row(children: [
        Expanded(child: uField(wn, 'Nomi (Asosiy karta)', max: 30)),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: wt,
            isExpanded: true,
            dropdownColor: C.bg2,
            decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
            items: [for (final t in kWalletTypes) DropdownMenuItem(value: t, child: Text(t))],
            onChanged: (v) => setState(() => wt = v ?? wt),
          ),
        ),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: uField(wc, 'Karta raqami (ixtiyoriy)', kt: TextInputType.number, max: 23)),
        const SizedBox(width: 8),
        Expanded(child: uField(wb, 'Qoldiq', num: true)),
      ]),
      const SizedBox(height: 10),
      uBtn('Hamyon qo\'shish', () {
        final n = wn.text.trim();
        final bl = wb.text.trim().isEmpty ? 0.0 : parseAmount(wb.text);
        final dg = wc.text.replaceAll(RegExp(r'\D'), '');
        if (n.length < 2) return _msg('Nomini kiriting.');
        if (bl == null) return _msg('Qoldiqni raqam bilan kiriting.');
        if (dg.isNotEmpty && dg.length != 16) return _msg('Karta raqami 16 ta raqam bo\'lsin.');
        w.add({'id': nid(), 'name': n, 'type': wt, 'bal': bl, 'last4': dg.isEmpty ? '' : dg.substring(12)});
        wn.clear();
        wc.clear();
        wb.clear();
        _done('Qo\'shildi');
      }),
      if (w.length > 1) ...[
        const Divider(height: 28, color: C.line),
        const Text('O\'tkazma', style: TextStyle(fontWeight: FontWeight.w700, color: C.dim)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _walDrop(w, tfF, (v) => setState(() => tfF = v))),
          const SizedBox(width: 8),
          Expanded(child: _walDrop(w, tfT, (v) => setState(() => tfT = v))),
        ]),
        const SizedBox(height: 8),
        uField(tfA, 'Summa', num: true),
        const SizedBox(height: 10),
        uBtn("O'tkazish", () {
          final m = parseAmount(tfA.text);
          Map<String, dynamic>? f, t2;
          for (final x in w) {
            if (x['id'] == tfF) f = x;
            if (x['id'] == tfT) t2 = x;
          }
          if (f == null || t2 == null || f == t2) return _msg('Ikki xil hamyon tanlang.');
          if (m == null || m <= 0) return _msg('Summani kiriting.');
          if (m > ((f['bal'] ?? 0) as num)) return _msg('Qoldiq yetarli emas.');
          f['bal'] = r2(((f['bal'] ?? 0) as num).toDouble() - m);
          t2['bal'] = r2(((t2['bal'] ?? 0) as num).toDouble() + m);
          tfA.clear();
          _done("O'tkazildi");
        }, ghost: true),
      ],
    ]);
  }

  Widget _walDrop(List<Map<String, dynamic>> w, String v, ValueChanged<String> f) => DropdownButtonFormField<String>(
        value: v.isEmpty ? null : v,
        isExpanded: true,
        dropdownColor: C.bg2,
        decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
        items: [for (final x in w) DropdownMenuItem(value: '${x['id']}', child: Text('${x['name']}', overflow: TextOverflow.ellipsis))],
        onChanged: (x) => f(x ?? v),
      );

  /* ---- net worth ---- */
  Widget _netWorth(({double cash, double card, double sav, double debt, double recv, double net}) n) {
    final nw = p.mp('nw');
    final nks = nw.keys.toList()..sort();
    final ck = monthKeyOf(DateTime.now());
    final prevKeys = nks.where((k) => k.compareTo(ck) < 0).toList();
    final pk0 = prevKeys.isEmpty ? null : prevKeys.last;
    final nd = pk0 == null ? null : n.net - ((nw[pk0] ?? 0) as num).toDouble();
    var nmx = 1.0;
    final last6 = nks.length > 6 ? nks.sublist(nks.length - 6) : nks;
    for (final k in last6) {
      nmx = math.max(nmx, ((nw[k] ?? 0) as num).abs().toDouble());
    }
    String sg(double v) => v < 0 ? '−' : '';
    return uCard('Sof boylik', sub: mny(n.net), children: [
      uSmall('Naqd, kartalar va jamg\'armalar minus qarzlaringiz.${nd == null ? '' : " O'tgan oyga nisbatan: ${nd >= 0 ? '+' : '−'}${mny(nd.abs())}."}'),
      for (final r in [('Naqd pul', n.cash), ('Kartalar', n.card), ("Jamg'armalar", n.sav), ('Qarzlarim (men qarzdorman)', -n.debt)]) URow(title: r.$1, amount: '${sg(r.$2)}${mny(r.$2.abs())}', amountColor: r.$2 < 0 ? C.out : null),
      URow(title: 'Sof boylik', amount: '${sg(n.net)}${mny(n.net.abs())}'),
      if (n.recv > 0) uSmall('Hisobga kirmagan: menga qaytadigan qarz ${mny(n.recv)}.'),
      if (nks.length > 1)
        for (final k in last6)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(mlab(k), style: const TextStyle(fontSize: 12.5, color: C.dim)), Text('${sg(((nw[k] ?? 0) as num).toDouble())}${mny(((nw[k] ?? 0) as num).abs())}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5))]),
              const SizedBox(height: 4),
              uBar(math.max(.02, ((nw[k] ?? 0) as num).abs().toDouble() / nmx), ((nw[k] ?? 0) as num) < 0 ? C.out : C.accent),
            ]),
          ),
    ]);
  }

  /* ---- recurring ---- */
  Widget _recur() {
    final r = p.lst('recur');
    return uCard("Takroriy to'lovlar", children: [
      if (r.isEmpty) uSmall('Hali takroriy to\'lov yo\'q. Ijara, internet yoki obuna qo\'shing: har oy avtomatik yoziladi.'),
      for (final x in r)
        Builder(builder: (c) {
          final d = daysTo(((x['day'] ?? 1) as num).toInt());
          return URow(title: '${x['name']}', sub: 'Har oy ${x['day']}-kuni · ${d > 0 ? '$d kun qoldi' : 'bugun'}', amount: mny((x['amt'] ?? 0) as num), late: d <= 3, action: SureBtn(onSure: () {
            p.x['recur'] = r.where((y) => y['id'] != x['id']).toList();
            _done();
          }));
        }),
      uField(rn, 'Nomi (Ijara)', max: 30),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: rc,
        isExpanded: true,
        dropdownColor: C.bg2,
        decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
        items: [for (final c in catsOf('out')) DropdownMenuItem(value: c.id, child: Text(c.name))],
        onChanged: (v) => setState(() => rc = v ?? rc),
      ),
      const SizedBox(height: 8),
      Row(children: [Expanded(child: uField(ra, 'Summa', num: true)), const SizedBox(width: 8), Expanded(child: uField(rd, 'Oyning kuni (1-31)', kt: TextInputType.number))]),
      const SizedBox(height: 10),
      uBtn('Qo\'shish', () {
        final n = rn.text.trim();
        final a = parseAmount(ra.text);
        final dd = parseAmount(rd.text)?.round();
        if (n.length < 2) return _msg('Nomini kiriting.');
        if (a == null || a <= 0) return _msg('Summani kiriting.');
        if (dd == null || dd < 1 || dd > 31) return _msg('Kun 1 dan 31 gacha bo\'lsin.');
        r.add({'id': nid(), 'name': n, 'amt': a, 'day': dd, 'cat': rc, 'last': DateTime.now().day >= dd ? monthKeyOf(DateTime.now()) : ''});
        rn.clear();
        ra.clear();
        rd.clear();
        _done('Qo\'shildi');
      }),
    ]);
  }

  /* ---- debts ---- */
  Widget _debts() {
    final ds = p.lst('debts');
    var dIn = 0.0, dOut = 0.0;
    for (final x in ds) {
      final a = ((x['amt'] ?? 0) as num).toDouble();
      if (x['dir'] == 'in') {
        dIn += a;
      } else {
        dOut += a;
      }
    }
    return uCard('Qarz daftari', sub: 'Menga: ${mny(dIn)} · Men: ${mny(dOut)}', children: [
      if (ds.isEmpty) uSmall('Qarzlar yo\'q. Kim kimga qarzdorligini yozib boring.'),
      for (final x in ds)
        Builder(builder: (c) {
          final due = '${x['due'] ?? ''}';
          final late = due.isNotEmpty && dueIn(due) < 0;
          return URow(title: '${x['who']}', sub: '${x['dir'] == 'in' ? 'Menga qarzdor' : 'Men qarzdorman'}${due.isNotEmpty ? ' · $due' : ''}${late ? " · muddati o'tgan" : ''}', amount: mny((x['amt'] ?? 0) as num), late: late, action: SureBtn(onSure: () {
            p.x['debts'] = ds.where((y) => y['id'] != x['id']).toList();
            _done();
          }));
        }),
      Row(children: [Expanded(child: uField(dw, 'Kim bilan', max: 30)), const SizedBox(width: 8), Expanded(child: uField(da, 'Summa', num: true))]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: dr,
            isExpanded: true,
            dropdownColor: C.bg2,
            decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
            items: const [DropdownMenuItem(value: 'in', child: Text('Menga qarzdor')), DropdownMenuItem(value: 'out', child: Text('Men qarzdorman'))],
            onChanged: (v) => setState(() => dr = v ?? dr),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: () async {
              final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
              if (d != null) setState(() => de.text = dayKey(d));
            },
            child: IgnorePointer(child: uField(de, 'Muddat (ixtiyoriy)')),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      uBtn('Qo\'shish', () {
        final w = dw.text.trim();
        final a = parseAmount(da.text);
        if (w.length < 2) return _msg('Ismni kiriting.');
        if (a == null || a <= 0) return _msg('Summani kiriting.');
        ds.add({'id': nid(), 'who': w, 'amt': a, 'dir': dr == 'out' ? 'out' : 'in', 'due': de.text.trim()});
        dw.clear();
        da.clear();
        de.clear();
        _done('Qo\'shildi');
      }),
    ]);
  }

  /* ---- budget ---- */
  Widget _budget() {
    final b = p.mp('budget');
    final bo = app.byCat(mk, 'out');
    var plan = 0.0, spent = 0.0;
    for (final c in catsOf('out')) {
      plan += ((b[c.id] ?? 0) as num).toDouble();
      spent += bo[c.id] ?? 0;
    }
    return uCard('Byudjet rejasi', sub: mlab(mk), children: [
      uSmall('Reja: ${mny(plan)} · Sarflangan: ${mny(spent)}'),
      for (final c in catsOf('out'))
        Builder(builder: (ctx) {
          final pl = ((b[c.id] ?? 0) as num).toDouble(), sp_ = bo[c.id] ?? 0;
          final ctrl = bud.putIfAbsent(c.id, () => TextEditingController(text: pl > 0 ? '${pl % 1 == 0 ? pl.toInt() : pl}' : ''));
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.name, style: const TextStyle(fontSize: 12.5, color: C.dim, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              uField(ctrl, 'Reja', num: true),
              const SizedBox(height: 6),
              uBar(pl > 0 ? sp_ / pl : 0, pl > 0 && sp_ > pl ? C.out : c.color),
              const SizedBox(height: 2),
              Text('${mny(sp_)}${pl > 0 ? ' / ${mny(pl)}' : ''}', style: const TextStyle(color: C.mute, fontSize: 12)),
            ]),
          );
        }),
      uBtn('Rejani saqlash', () {
        final nb = <String, dynamic>{};
        for (final c in catsOf('out')) {
          final t = bud[c.id]?.text.trim() ?? '';
          final v = t.isEmpty ? 0.0 : parseAmount(t);
          if (v == null || v < 0) return _msg('Rejani raqam bilan kiriting.');
          if (v > 0) nb[c.id] = v;
        }
        p.x['budget'] = nb;
        _done('Reja saqlandi');
      }),
    ]);
  }

  /* ---- monthly report ---- */
  Widget _report(({double cash, double card, double sav, double debt, double recv, double net}) n) {
    final s = app.sums(mk);
    final bo = app.byCat(mk, 'out');
    var tot = 0.0;
    for (final w in p.lst('wallets')) {
      tot += ((w['bal'] ?? 0) as num).toDouble();
    }
    final rows = <(String, String)>[
      ('Kirim', mny(s.i)),
      ('Chiqim', mny(s.o)),
      ('Farq', '${s.i - s.o < 0 ? '−' : ''}${mny((s.i - s.o).abs())}'),
      for (final c in catsOf('out')) if ((bo[c.id] ?? 0) > 0) (c.name, mny(bo[c.id]!)),
      ('Hamyonlar jami', mny(tot)),
      ('Qarzlarim', mny(n.debt)),
    ];
    return uCard('Hisobot: ${mlab(mk)}', sub: p.name, children: [
      for (final r in rows) URow(title: r.$1, amount: r.$2),
      const SizedBox(height: 6),
      uBtn('Hisobotni nusxalash', () async {
        final txt = StringBuffer('VAULT hisobot: ${mlab(mk)} (${p.name} ${p.surname})\n');
        for (final r in rows) {
          txt.writeln('${r.$1}: ${r.$2}');
        }
        await Clipboard.setData(ClipboardData(text: txt.toString()));
        if (mounted) _msg('Hisobot nusxalandi');
      }, ghost: true),
    ]);
  }

  /* ---- financial memory ---- */
  Widget _memory(({double cash, double card, double sav, double debt, double recv, double net}) nwv, Set<String> keys) {
    final ms = app.sums(mk);
    final bo = app.byCat(mk, 'out');
    final outs = app.listOf(mk).where((x) => x.t == 'out').toList()..sort((a, b) => b.a.compareTo(a.a));
    final ttx = outs.isEmpty ? null : outs.first;
    final pvo = app.sums(prevMonthKey(mk)).o;
    Cat? tcat;
    var tcv = 0.0;
    for (final c in catsOf('out')) {
      if ((bo[c.id] ?? 0) > tcv) {
        tcv = bo[c.id]!;
        tcat = c;
      }
    }
    final svd = ms.i - ms.o;
    final rate = ms.i > 0 ? (svd / ms.i * 100).round() : null;
    var over = 0;
    final b = p.mp('budget');
    for (final c in catsOf('out')) {
      final pl = ((b[c.id] ?? 0) as num).toDouble();
      if (pl > 0 && (bo[c.id] ?? 0) > pl) over++;
    }
    if (memo.text.isEmpty) memo.text = '${p.mp('memo')[mk] ?? ''}';
    final mem = p.mp('mem');
    final mks = mem.keys.where((k) => k != mk).toList()..sort((a, b) => b.compareTo(a));
    return uCard('Moliyaviy xotira', sub: mlab(mk), children: [
      uSmall('Oy hisoboti: natijalar va keyingi oy uchun reja. Har oy tarixga saqlanadi.'),
      URow(title: 'Kirim / chiqim', sub: 'Farq${rate == null ? '' : " · jamg'arma darajasi $rate%"}', amount: '${mny(ms.i)} / ${mny(ms.o)}\n${svd < 0 ? '−' : ''}${mny(svd.abs())}'),
      URow(title: 'Eng katta xarajat', sub: ttx == null ? "Chiqim yo'q" : '${catOf('out', ttx.c).name}${ttx.n.isNotEmpty ? ' · ${ttx.n}' : ''}', amount: ttx == null ? '—' : mny(ttx.a)),
      URow(title: "Eng ko'p sarflangan kategoriya", sub: pvo > 0 ? "O'tgan oyga nisbatan chiqim: ${ms.o >= pvo ? '+' : '−'}${((ms.o - pvo).abs() / pvo * 100).round()}%" : "O'tgan oyda ma'lumot yo'q", amount: tcat == null ? '—' : '${tcat.name}\n${mny(tcv)}'),
      if (b.isNotEmpty) URow(title: 'Byudjet', sub: 'Rejadan oshgan kategoriyalar', amount: '$over ta'),
      URow(title: 'Sof boylik', sub: 'Joriy holat', amount: '${nwv.net < 0 ? '−' : ''}${mny(nwv.net.abs())}'),
      for (final g in p.goals) URow(title: 'Maqsad: ${g.name}', sub: g.target > 0 && g.saved >= g.target ? 'Erishildi' : '${g.target > 0 ? (math.min(1.0, g.saved / g.target) * 100).round() : 0}% bajarildi', amount: mny(g.saved)),
      const SizedBox(height: 6),
      const Text('Kelgusi oy rejasi', style: TextStyle(fontWeight: FontWeight.w700, color: C.dim, fontSize: 12.5)),
      const SizedBox(height: 6),
      TextField(controller: memo, maxLength: 600, maxLines: 3, decoration: const InputDecoration(hintText: 'Masalan: oziq-ovqatni 10% kamaytirish, maqsadga 500 000 qo\'shish')),
      uBtn('Rejani saqlash', () {
        p.mp('memo')[mk] = memo.text.trim();
        _done('Reja saqlandi');
      }),
      if (mks.isNotEmpty) ...[
        const SizedBox(height: 14),
        const Text('Tarix', style: TextStyle(fontWeight: FontWeight.w700, color: C.dim)),
        for (final k in mks)
          Builder(builder: (c) {
            final m = Map<String, dynamic>.from(mem[k] as Map);
            final i = ((m['i'] ?? 0) as num).toDouble(), o = ((m['o'] ?? 0) as num).toDouble();
            return ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('${mlab(k)} · ${i - o < 0 ? '−' : ''}${mny((i - o).abs())}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              children: [Align(alignment: Alignment.centerLeft, child: uSmall('Kirim ${mny(i)} · Chiqim ${mny(o)}${m['tc'] != null ? ' · Asosiy kategoriya: ${m['tc']}' : ''}${((m['tt'] ?? 0) as num) > 0 ? ' · Eng katta xarajat: ${mny((m['tt']) as num)}' : ''}${('${p.mp('memo')[k] ?? ''}').isNotEmpty ? '\nReja: ${p.mp('memo')[k]}' : ''}'))],
            );
          }),
      ],
    ]);
  }

  /* ---- daily budget ---- */
  Widget _daily() {
    final b = p.mp('budget');
    var dbL = p.limit > 0 ? p.limit : 0.0;
    if (dbL <= 0) {
      for (final c in catsOf('out')) {
        dbL += ((b[c.id] ?? 0) as num).toDouble();
      }
    }
    final isCur = mk == monthKeyOf(DateTime.now());
    final kids = <Widget>[];
    if (!(dbL > 0)) {
      kids.add(uSmall('Oylik limit qo\'ying (Profil) yoki Reja bo\'limida byudjet kiriting.'));
    } else if (!isCur) {
      kids.add(uSmall('Kunlik taqsimot faqat joriy oy uchun ishlaydi.'));
    } else {
      final pp = mk.split('-');
      final n = daysIn(int.parse(pp[0]), int.parse(pp[1]));
      final t0 = DateTime.now().day;
      final dbR = n - t0 + 1;
      final outs = app.listOf(mk).where((x) => x.t == 'out');
      double dayOut(int d) => outs.where((x) => x.d == '$mk-${two(d)}').fold<double>(0, (a, x) => a + x.a);
      var dbB = 0.0;
      for (var k = 1; k < t0; k++) {
        dbB += dayOut(k);
      }
      final dbS = dayOut(t0);
      final dbLim = math.max(0.0, (dbL - dbB) / dbR);
      final dbLeft = dbLim - dbS;
      final dbTot = dbB + dbS;
      final dbNx = dbR > 1 ? math.max(0.0, (dbL - dbTot) / (dbR - 1)) : 0.0;
      final dbBase = dbL / n;
      final dbPc = dbLim > 0 ? math.min(1.0, dbS / dbLim) : (dbS > 0 ? 1.0 : 0.0);
      kids.addAll([
        uSmall('Oylik ${p.limit > 0 ? 'limit' : 'byudjet'} ${mny(dbL)} qolgan $dbR kunga teng taqsimlanadi. Har kuni qayta hisoblanadi.'),
        uBar(dbPc, dbS > dbLim ? C.out : dbPc >= .75 ? C.warn : C.accent),
        const SizedBox(height: 10),
        URow(title: 'Bugungi limit', sub: 'Sarflangan: ${mny(dbS)}', amount: dbLeft < 0 ? '−${mny(-dbLeft)} oshdi' : '${mny(dbLeft)} qoldi', amountColor: dbLeft < 0 ? C.out : null),
        URow(title: 'Keyingi kunlar uchun kunlik limit', sub: 'Oy boshida: ${mny(dbBase)}', amount: dbR > 1 ? mny(dbNx) : '—'),
        URow(title: 'Oy oxirigacha qoldi', sub: '$dbR kun, shu jumladan bugun', amount: '${dbL - dbTot < 0 ? '−' : ''}${mny((dbL - dbTot).abs())}', amountColor: dbL - dbTot < 0 ? C.out : null),
        NoteBox(dbTot > dbL ? 'Oylik limitdan ${mny(dbTot - dbL)} oshdi. Keyingi kunlar uchun limit qolmadi.' : dbS > dbLim ? 'Bugun limitdan ${mny(dbS - dbLim)} oshdi. Keyingi kunlar uchun kunlik limit ${mny(dbNx)} ga ${dbNx < dbBase ? 'kamaydi' : "o'zgardi"}.' : 'Bugun limit ichida. Qolgan ${mny(dbLeft)} ni sarflashingiz mumkin.'),
      ]);
    }
    return uCard('Kunlik byudjet', sub: mlab(mk), children: kids);
  }

  /* ---- where did the money go ---- */
  Widget _where() {
    final isCur = mk == monthKeyOf(DateTime.now());
    final pp = mk.split('-');
    final wgN = isCur ? DateTime.now().day : daysIn(int.parse(pp[0]), int.parse(pp[1]));
    final pm = prevMonthKey(mk);
    final prev = app.listOf(pm).where((x) => x.t == 'out' && int.parse(x.d.substring(8, 10)) <= wgN);
    final pb = <String, double>{};
    var pt = 0.0;
    for (final x in prev) {
      pb[x.c] = (pb[x.c] ?? 0) + x.a;
      pt += x.a;
    }
    final cb = app.byCat(mk, 'out');
    final ct = app.sums(mk).o;
    final kids = <Widget>[];
    if (pt <= 0) {
      kids.add(uSmall("O'tgan oyda solishtirish uchun chiqim yo'q."));
    } else {
      final keys = {...cb.keys, ...pb.keys};
      final rows = keys.map((k) => (k, cb[k] ?? 0.0, pb[k] ?? 0.0)).toList()..sort((a, b) => (b.$2 - b.$3).abs().compareTo((a.$2 - a.$3).abs()));
      final up = rows.where((r) => r.$2 - r.$3 > 0).toList()..sort((a, b) => (b.$2 - b.$3).compareTo(a.$2 - a.$3));
      final dn = rows.where((r) => r.$2 - r.$3 < 0).toList()..sort((a, b) => (a.$2 - a.$3).compareTo(b.$2 - b.$3));
      kids.addAll([
        uSmall(isCur ? "Oyning dastlabki $wgN kuni o'tgan oyning shu davri bilan solishtirildi." : "To'liq oy o'tgan oy bilan solishtirildi."),
        NoteBox("Jami chiqim: ${mny(ct)} (o'tgan oy: ${mny(pt)}), ${ct >= pt ? '+' : '−'}${mny((ct - pt).abs())} · ${ct >= pt ? '+' : '−'}${((ct - pt).abs() / pt * 100).round()}%.${up.isNotEmpty ? " Eng ko'p oshgan: ${catOf('out', up.first.$1).name} (+${mny(up.first.$2 - up.first.$3)})." : ''}${dn.isNotEmpty ? " Eng ko'p kamaygan: ${catOf('out', dn.first.$1).name} (−${mny((dn.first.$2 - dn.first.$3).abs())})." : ''}"),
        const SizedBox(height: 8),
        for (final r in rows)
          URow(title: catOf('out', r.$1).name, sub: "${mny(r.$2)} · o'tgan oy: ${mny(r.$3)}", amount: '${r.$2 - r.$3 > 0 ? '+' : r.$2 - r.$3 < 0 ? '−' : ''}${mny((r.$2 - r.$3).abs())}', amountColor: r.$2 - r.$3 > 0 ? C.out : r.$2 - r.$3 < 0 ? C.accent : null),
      ]);
    }
    return uCard('Pul qayerga ketdi?', sub: mlab(mk), children: kids);
  }

  /* ---- receipt (manual entry; OCR is not available in this Flutter build) ---- */
  Widget _receipt() {
    final w = p.lst('wallets');
    return uCard('Chek bo\'yicha chiqim', sub: 'Qo\'lda', children: [
      uSmall('Chekdagi ma\'lumotlarni kiriting: summa, sana va savdo joyi. (Rasmdan avtomatik o\'qish bu ilovada hali yo\'q.)'),
      uField(sa, 'Summa', num: true),
      const SizedBox(height: 8),
      uField(sn, 'Savdo joyi / izoh', max: 60),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: sc,
            isExpanded: true,
            dropdownColor: C.bg2,
            decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
            items: [for (final c in catsOf('out')) DropdownMenuItem(value: c.id, child: Text(c.name))],
            onChanged: (v) => setState(() => sc = v ?? sc),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: () async {
              final d = await showDatePicker(context: context, initialDate: parseDay(sd), firstDate: DateTime(2000), lastDate: DateTime.now().add(const Duration(days: 366)));
              if (d != null) setState(() => sd = dayKey(d));
            },
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), side: const BorderSide(color: C.line), foregroundColor: C.ink),
            child: Text(sd),
          ),
        ),
      ]),
      if (w.isNotEmpty) ...[
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: sw,
          isExpanded: true,
          dropdownColor: C.bg2,
          decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
          items: [const DropdownMenuItem(value: '', child: Text('Hamyon: tanlanmagan')), for (final x in w) DropdownMenuItem(value: '${x['id']}', child: Text('${x['name']}'))],
          onChanged: (v) => setState(() => sw = v ?? ''),
        ),
      ],
      const SizedBox(height: 10),
      uBtn('Chiqim qo\'shish', () async {
        final v = parseAmount(sa.text);
        if (v == null || v <= 0 || v > 1e12) return _msg('Summa va sanani tekshiring.');
        await app.addTx(Tx(id: newId(), t: 'out', a: fixAmt(v), c: sc, n: sn.text.trim(), d: sd, ts: DateTime.now().millisecondsSinceEpoch, ex: {if (sw.isNotEmpty) 'w': sw}));
        sa.clear();
        sn.clear();
        if (mounted) _msg('Chiqim qo\'shildi: −${grp(fixAmt(v))} ${curUnit()}');
      }),
    ]);
  }

  /* ---- missions ---- */
  Widget _missions() {
    final ms = p.mp('missions');
    var done = 0;
    for (final m in kMissions) {
      final r = ms[m.id];
      if (r != null && '${r['done']}'.isNotEmpty && r['done'] != null) done++;
    }
    return uCard('Moliyaviy missiyalar', sub: 'Olam: ${p.x['olam'] ?? 0} ball', children: [
      uSmall('Ixtiyoriy vazifalar. Har biri bajarilsa Olam ballari beriladi. Yutuqlar: $done / ${kMissions.length}.'),
      for (final m in kMissions)
        Builder(builder: (c) {
          final st = misState(m.id);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color(0x08FFFFFF), border: Border.all(color: C.line)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(misT(m), style: const TextStyle(fontWeight: FontWeight.w700))),
                if (st.s == 'idle' || st.s == 'fail')
                  TextButton(
                    onPressed: () {
                      ms[m.id] = {'start': todayStr(), 'done': ''};
                      final msg = evalMissions();
                      app.saveProfile();
                      _msg(msg.isNotEmpty ? msg : 'Missiya boshlandi');
                    },
                    child: Text(st.s == 'idle' ? 'Boshlash' : 'Qayta boshlash', style: const TextStyle(color: C.accent, fontWeight: FontWeight.w800)),
                  )
                else
                  Text(st.s == 'done' ? '✓' : '${(st.p * 100).round()}%', style: TextStyle(fontWeight: FontWeight.w800, color: st.s == 'done' ? C.accent : C.ink)),
              ]),
              Text('${misD(m)} · +${m.pts} Olam', style: const TextStyle(color: C.dim, fontSize: 12.5)),
              if (st.s == 'run' || st.s == 'win' || st.s == 'fail') ...[const SizedBox(height: 8), uBar(st.p, st.s == 'fail' ? C.out : C.accent)],
              if (st.x.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(st.x, style: TextStyle(color: st.s == 'fail' ? C.out : C.mute, fontSize: 12))),
            ]),
          );
        }),
    ]);
  }

  /* ---- backup ---- */
  static const _bkeys = ['wallets', 'recur', 'debts', 'budget', 'goals', 'catLimits', 'theme', 'nw', 'mem', 'memo', 'missions', 'olam', 'biz', 'inv', 'bizTax', 'fam', 'el', 'vc'];

  Widget _backup() => uCard('Zaxira', children: [
        TextField(controller: bk, maxLines: 4, decoration: const InputDecoration(hintText: 'Zaxira matni shu yerda chiqadi. Tiklash uchun matnni shu yerga qo\'ying.')),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: uBtn('Zaxira yaratish', () async {
              final j = p.toJson();
              final o = <String, dynamic>{};
              for (final k in _bkeys) {
                if (j[k] != null) o[k] = j[k];
              }
              bk.text = jsonEncode(o);
              await Clipboard.setData(ClipboardData(text: bk.text));
              if (mounted) _msg('Zaxira nusxalandi');
            }, ghost: true),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: uBtn('Tiklash', () async {
              Object? o;
              try {
                o = jsonDecode(bk.text.trim());
              } catch (_) {
                return _msg("Zaxira matni noto'g'ri.");
              }
              if (o is! Map) return _msg("Zaxira matni noto'g'ri.");
              final m = Map<String, dynamic>.from(o);
              for (final k in ['wallets', 'recur', 'debts', 'inv', 'bizTax']) {
                if (m[k] is List) p.x[k] = m[k];
              }
              if (m['goals'] is List) p.goals = (m['goals'] as List).map((e) => Goal.fromJson(Map<String, dynamic>.from(e as Map))).toList();
              for (final k in ['budget', 'catLimits', 'nw', 'mem', 'memo', 'missions', 'biz', 'el']) {
                if (m[k] is Map) p.x[k] = Map<String, dynamic>.from(m[k] as Map);
              }
              if (m['vc'] is Map && (m['vc'] as Map)['cards'] is List) {
                p.cards = ((m['vc'] as Map)['cards'] as List).map((e) => VCard.fromJson(Map<String, dynamic>.from(e as Map))).toList();
              }
              if (kThemes.containsKey(m['theme'])) p.x['theme'] = m['theme'];
              if (m['olam'] is num && (m['olam'] as num) >= 0) p.x['olam'] = m['olam'];
              await _done('Tiklandi');
            }),
          ),
        ]),
      ]);

  /* ---- theme color ---- */
  Widget _theme() {
    final cur = '${p.x['theme'] ?? 'blue'}';
    return uCard('Mavzu rangi', children: [
      Wrap(spacing: 12, children: [
        for (final e in kThemes.entries)
          GestureDetector(
            onTap: () {
              p.x['theme'] = e.key;
              _done();
            },
            child: Container(width: 44, height: 44, decoration: BoxDecoration(shape: BoxShape.circle, color: e.value[0] as Color, border: Border.all(color: cur == e.key ? Colors.white : Colors.transparent, width: 2.5)), child: cur == e.key ? const Icon(Icons.check_rounded, color: Colors.white) : null),
          ),
      ]),
      const SizedBox(height: 8),
      uSmall('Tanlangan rang asosiy tugmalar va balans kartasida qo\'llanadi.'),
    ]);
  }
}

/* ====================================================================== */
/*  BIZNES: P&L · business ops · invoices · clients · tax · settings       */
/* ====================================================================== */
const Map<String, String> kInvL = {'paid': "To'langan", 'late': "Muddati o'tgan", 'open': 'Kutilmoqda'};

({double i, double o, Map<String, double> bi, Map<String, double> bo}) bsum(String mk) {
  var i = 0.0, o = 0.0;
  final bi = <String, double>{}, bo = <String, double>{};
  for (final x in app.listOf(mk)) {
    if (x.ex['b'] == null) continue;
    if (x.t == 'in') {
      i += x.a;
      bi[x.c] = (bi[x.c] ?? 0) + x.a;
    } else {
      o += x.a;
      bo[x.c] = (bo[x.c] ?? 0) + x.a;
    }
  }
  return (i: i, o: o, bi: bi, bo: bo);
}

({double sub, double vat, double tot}) invCalc(List items, double vat) {
  var sb = 0.0;
  for (final it in items) {
    sb += ((it['q'] ?? 0) as num) * ((it['p'] ?? 0) as num);
  }
  final vt = sb * vat / 100;
  return (sub: fixAmt(sb), vat: fixAmt(vt), tot: fixAmt(sb + vt));
}

String invSt(Map v) {
  final paid = ((v['paid'] ?? 0) as num).toDouble(), total = ((v['total'] ?? 0) as num).toDouble();
  if (paid >= total - .001) return 'paid';
  final due = '${v['due'] ?? ''}';
  return due.isNotEmpty && due.compareTo(todayStr()) < 0 ? 'late' : 'open';
}

String invText(Map v) {
  final p = app.profile!;
  final B = p.mp('biz');
  final c = invCalc(v['items'] as List, ((v['vat'] ?? 0) as num).toDouble());
  final b = StringBuffer('Hisob-faktura № ${v['no']}\nSana: ${v['date']}${'${v['due'] ?? ''}'.isNotEmpty ? " · To'lov muddati: ${v['due']}" : ''}\n');
  b.writeln("Sotuvchi: ${'${B['name'] ?? ''}'.isEmpty ? p.name : B['name']}${'${B['inn'] ?? ''}'.isNotEmpty ? ' · STIR: ${B['inn']}' : ''}${'${B['phone'] ?? ''}'.isNotEmpty ? ' · Tel: ${B['phone']}' : ''}");
  b.writeln('Xaridor: ${v['client']}\n');
  for (final it in v['items'] as List) {
    b.writeln('${it['n']}: ${it['q']} × ${mny(it['p'] as num)} = ${mny((it['q'] as num) * (it['p'] as num))}');
  }
  b.writeln('\nJami: ${mny(c.sub)}');
  if (((v['vat'] ?? 0) as num) > 0) b.writeln('QQS (${v['vat']}%): ${mny(c.vat)}');
  b.writeln("To'lanishi kerak: ${mny(c.tot)}");
  final paid = ((v['paid'] ?? 0) as num).toDouble();
  if (paid > 0) {
    b.writeln("To'langan: ${mny(paid)}");
    b.writeln('Qoldiq: ${mny(math.max(0, c.tot - paid))}');
  }
  if ('${B['req'] ?? ''}'.isNotEmpty) b.writeln("\nTo'lov rekvizitlari: ${B['req']}");
  return b.toString();
}

class BizTab extends StatefulWidget {
  final ShellApi api;
  const BizTab({super.key, required this.api});
  @override
  State<BizTab> createState() => _BizTabState();
}

class _BizTabState extends State<BizTab> {
  int _tab = 0;
  String mk = monthKeyOf(DateTime.now());
  static const _groups = ['Hisobot', 'Operatsiya', 'Hisob-faktura', 'Mijozlar', 'Soliq', 'Sozlama'];
  Profile get p => app.profile!;

  // ops
  String bType = 'out', bCat = 'b_stock', bDate = todayStr();
  final ba = TextEditingController(), bn = TextEditingController();
  // invoice draft
  final List<Map<String, dynamic>> draft = [];
  final icl = TextEditingController(), ivt = TextEditingController(), iin = TextEditingController(), iiq = TextEditingController(text: '1'), iip = TextEditingController();
  String idt = todayStr(), idu = '';
  final Map<String, TextEditingController> payC = {};
  // tax
  final trc = TextEditingController(), tn = TextEditingController(), ta = TextEditingController(), td = TextEditingController();
  String tk = 'm', tdt = '';
  // settings
  final bnm = TextEditingController(), bi = TextEditingController(), bp = TextEditingController(), bq = TextEditingController();
  bool _init = false;

  void _msg(String m) => toast(context, m);
  Future<void> _done([String? m]) async {
    await app.saveProfile();
    if (mounted) {
      setState(() {});
      if (m != null) _msg(m);
    }
  }

  @override
  void dispose() {
    for (final c in [ba, bn, icl, ivt, iin, iiq, iip, trc, tn, ta, td, bnm, bi, bp, bq, ...payC.values]) {
      c.dispose();
    }
    super.dispose();
  }

  List<Cat> _bzCats(String t) {
    final l = catsOf(t);
    final b = l.where((c) => c.id.startsWith('b_')).toList();
    return [...b, ...l.where((c) => !c.id.startsWith('b_'))];
  }

  void _shift(int d) {
    final pp = mk.split('-');
    final n = DateTime(int.parse(pp[0]), int.parse(pp[1]) + d, 1);
    final nk = monthKeyOf(n);
    if (nk.compareTo(monthKeyOf(DateTime.now())) > 0) return;
    setState(() => mk = nk);
  }

  Future<void> _copy(String txt) async {
    await Clipboard.setData(ClipboardData(text: txt));
    if (mounted) _msg('Nusxalandi');
  }

  @override
  Widget build(BuildContext context) {
    if (!p.isBiz) {
      return ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Biznes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Hisob-faktura, mijozlar daftari, foyda/zarar hisoboti, soliq eslatmasi va biznes hisobini shaxsiydan ajratish.', style: TextStyle(color: C.dim)),
        const SizedBox(height: 16),
        PrimaryButton(label: "Biznes ga o'tish", onTap: () => widget.api.show('plans')),
      ]);
    }
    if (!_init) {
      _init = true;
      final B = p.mp('biz');
      bnm.text = '${B['name'] ?? ''}';
      bi.text = '${B['inn'] ?? ''}';
      bp.text = '${B['phone'] ?? ''}';
      bq.text = '${B['req'] ?? ''}';
      final r = ((B['taxRate'] ?? 0) as num).toDouble();
      trc.text = r > 0 ? '${r % 1 == 0 ? r.toInt() : r}' : '';
    }
    p.lst('inv');
    p.lst('bizTax');
    final tabs = [_report(), _ops(), _invoices(), _clients(), _tax(), _settings()];
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
      const Text('Biznes', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      const Text('Kichik biznes hisobi va moliyaviy boshqaruv.', style: TextStyle(color: C.dim, fontSize: 13.5)),
      const SizedBox(height: 12),
      SizedBox(
        height: 40,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (var i = 0; i < _groups.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_groups[i]),
                selected: _tab == i,
                onSelected: (_) => setState(() => _tab = i),
                selectedColor: C.accent.withOpacity(.2),
                backgroundColor: const Color(0x0AFFFFFF),
                side: BorderSide(color: _tab == i ? C.accent : C.line),
                labelStyle: TextStyle(color: _tab == i ? Colors.white : C.dim, fontWeight: FontWeight.w700),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 14),
      tabs[_tab],
    ]);
  }

  Widget _kpi(String k, String v, String s, {Color? col}) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.all(10),
          decoration: _glass(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(k, style: const TextStyle(color: C.dim, fontSize: 11.5)),
            const SizedBox(height: 4),
            FittedBox(fit: BoxFit.scaleDown, child: Text(v, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: col ?? C.ink))),
            const SizedBox(height: 2),
            Text(s, style: const TextStyle(color: C.mute, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      );

  /* 0: report */
  Widget _report() {
    final s = bsum(mk), ps = bsum(prevMonthKey(mk)), B = p.mp('biz'), inv = p.lst('inv');
    final pf = s.i - s.o, pp = ps.i - ps.o;
    final mg = s.i > 0 ? (pf / s.i * 100).round() : null;
    final rate = ((B['taxRate'] ?? 0) as num).toDouble();
    final tax = fixAmt(s.i * rate / 100);
    final bc = catsOf('out').where((c) => (s.bo[c.id] ?? 0) > 0).toList()..sort((a, b) => s.bo[b.id]!.compareTo(s.bo[a.id]!));
    final cl = <String, double>{}, it = <String, double>{};
    for (final v in inv) {
      final paid = ((v['paid'] ?? 0) as num).toDouble(), total = ((v['total'] ?? 0) as num).toDouble();
      final pa = '${v['paidAt'] ?? ''}';
      if (paid >= total - .001 && pa.length >= 7 && pa.substring(0, 7) == mk) {
        final k = '${v['client']}'.trim();
        cl[k] = (cl[k] ?? 0) + total;
        for (final x in v['items'] as List) {
          final n = '${x['n']}'.trim();
          it[n] = (it[n] ?? 0) + ((x['q'] as num) * (x['p'] as num));
        }
      }
    }
    String? top(Map<String, double> o) {
      String? b;
      o.forEach((k, v) {
        if (b == null || v > o[b]!) b = k;
      });
      return b;
    }

    final tcl = top(cl), tit = top(it);
    String sg(double v) => v < 0 ? '−' : '';
    final kids = <Widget>[
      Center(child: MonthBar(mk: mk, onShift: _shift)),
      Row(children: [_kpi('Tushum', mny(s.i), 'Biznes kirimi'), _kpi('Xarajat', mny(s.o), 'Biznes chiqimi'), _kpi('Foyda', '${sg(pf)}${mny(pf.abs())}', mg == null ? "Tushum yo'q" : 'Marja $mg%', col: pf < 0 ? C.out : C.accent)]),
      const SizedBox(height: 14),
      uCard('Foyda va zarar', sub: mlab(mk), children: [
        URow(title: "O'tgan oyga nisbatan foyda", sub: "O'tgan oy: ${sg(pp)}${mny(pp.abs())}", amount: '${pf >= pp ? '↑ +' : '↓ −'}${mny((pf - pp).abs())}', amountColor: pf >= pp ? C.accent : C.out),
        if (rate > 0) ...[
          URow(title: 'Taxminiy soliq (${rate % 1 == 0 ? rate.toInt() : rate}%)', sub: 'Tushumdan, taxminiy hisob', amount: mny(tax)),
          URow(title: 'Soliqdan keyingi foyda', amount: '${sg(pf - tax)}${mny((pf - tax).abs())}'),
        ],
        if (bc.isNotEmpty) ...[
          const SizedBox(height: 6),
          const Text('Xarajatlar tarkibi', style: TextStyle(color: C.dim, fontWeight: FontWeight.w700, fontSize: 12.5)),
          const SizedBox(height: 8),
          for (final c in bc)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: c.color, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(c.name, style: const TextStyle(fontSize: 13.5))),
                  Text('${mny(s.bo[c.id]!)} · ${(s.bo[c.id]! / s.o * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                ]),
                const SizedBox(height: 4),
                uBar(s.bo[c.id]! / s.o, c.color),
              ]),
            ),
        ],
        URow(title: 'Eng daromadli mijoz', sub: "To'liq to'langan hisob-fakturalar bo'yicha", amount: tcl == null ? '—' : '$tcl\n${mny(cl[tcl]!)}'),
        URow(title: 'Eng daromadli mahsulot yoki xizmat', sub: "To'liq to'langan hisob-fakturalar bo'yicha", amount: tit == null ? '—' : '$tit\n${mny(it[tit]!)}'),
        const SizedBox(height: 4),
        uBtn('Hisobotni nusxalash', () {
          final b = StringBuffer('Foyda va zarar hisoboti\n${'${B['name'] ?? ''}'.isEmpty ? p.name : B['name']} · ${mlab(mk)}\n\n');
          b.writeln('Tushum: ${mny(s.i)}\nXarajat: ${mny(s.o)}\nFoyda: ${sg(pf)}${mny(pf.abs())}');
          if (rate > 0) b.writeln('Taxminiy soliq ($rate%): ${mny(tax)}\nSoliqdan keyingi foyda: ${sg(pf - tax)}${mny((pf - tax).abs())}');
          b.writeln('\nKategoriyalar:');
          for (final c in [...catsOf('out'), ...catsOf('in')]) {
            final v = (s.bo[c.id] ?? 0) + (s.bi[c.id] ?? 0);
            if (v > 0) b.writeln('${c.name}: ${mny(v)}');
          }
          _copy(b.toString());
        }, ghost: true),
      ]),
      if (mk == monthKeyOf(DateTime.now())) _forecast(s, inv),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: kids);
  }

  Widget _forecast(({double i, double o, Map<String, double> bi, Map<String, double> bo}) s, List<Map<String, dynamic>> inv) {
    final pp = mk.split('-');
    final n = daysIn(int.parse(pp[0]), int.parse(pp[1]));
    final e = DateTime.now().day;
    final pi = s.i / e * n, po = s.o / e * n;
    var out = 0.0, late = 0.0;
    for (final v in inv) {
      final d = ((v['total'] ?? 0) as num).toDouble() - ((v['paid'] ?? 0) as num).toDouble();
      if (d > .001) {
        out += d;
        if (invSt(v) == 'late') late += d;
      }
    }
    return uCard('Oylik prognoz', children: [
      if (s.i + s.o > 0) ...[
        uSmall("Hozirgi sur'at ($e kun) davom etsa, oy oxirida:"),
        URow(title: 'Tushum', amount: mny(pi)),
        URow(title: 'Xarajat', amount: mny(po)),
        URow(title: 'Foyda', amount: '${pi - po < 0 ? '−' : ''}${mny((pi - po).abs())}'),
      ] else
        uSmall('Prognoz uchun biznes operatsiyalarini kiriting.'),
      URow(title: "Kutilayotgan to'lovlar", sub: "Hisob-fakturalar bo'yicha${late > 0 ? ", muddati o'tgan: ${mny(late)}" : ''}", amount: mny(out)),
    ]);
  }

  /* 1: operations */
  Widget _ops() {
    final cats = _bzCats(bType);
    if (!cats.any((c) => c.id == bCat)) bCat = cats.first.id;
    final bl = app.txs.where((x) => x.ex['b'] != null).toList()..sort((a, b) => b.ts.compareTo(a.ts));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      uCard('Biznes operatsiyasi', children: [
        uSmall("Bu yerda kiritilgan yozuvlar biznes hisobiga tushadi va umumiy hisobda ham ko'rinadi."),
        Row(children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: bType,
              isExpanded: true,
              dropdownColor: C.bg2,
              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
              items: const [DropdownMenuItem(value: 'out', child: Text('Chiqim')), DropdownMenuItem(value: 'in', child: Text('Kirim'))],
              onChanged: (v) => setState(() {
                bType = v == 'in' ? 'in' : 'out';
                bCat = _bzCats(bType).first.id;
              }),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: uField(ba, 'Summa', num: true)),
        ]),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: bCat,
          isExpanded: true,
          dropdownColor: C.bg2,
          decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
          items: [for (final c in cats) DropdownMenuItem(value: c.id, child: Text(c.name))],
          onChanged: (v) => setState(() => bCat = v ?? bCat),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: uField(bn, 'Izoh', max: 60)),
          const SizedBox(width: 8),
          Expanded(child: _dateBtn(bDate, (d) => setState(() => bDate = d))),
        ]),
        const SizedBox(height: 10),
        uBtn("Qo'shish", () async {
          final v = parseAmount(ba.text);
          if (v == null || v <= 0 || v > 1e12) return _msg("Summani to'g'ri kiriting.");
          final a = fixAmt(v);
          await app.addTx(Tx(id: newId(), t: bType, a: a, c: bCat, n: bn.text.trim(), d: bDate, ts: DateTime.now().millisecondsSinceEpoch, ex: {'b': 1}));
          ba.clear();
          bn.clear();
          if (mounted) {
            setState(() {});
            _msg('${bType == 'in' ? 'Biznes kirimi: +' : 'Biznes chiqimi: −'}${grp(a)} ${curUnit()}');
          }
        }),
      ]),
      uCard('Oxirgi biznes operatsiyalari', children: [
        if (bl.isEmpty) uSmall("Hali biznes operatsiyasi yo'q."),
        for (final x in bl.take(8)) TxTile(x),
      ]),
    ]);
  }

  Widget _dateBtn(String v, ValueChanged<String> f, {String hint = ''}) => OutlinedButton(
        onPressed: () async {
          final d = await showDatePicker(context: context, initialDate: v.isEmpty ? DateTime.now() : parseDay(v), firstDate: DateTime(2000), lastDate: DateTime(2100));
          if (d != null) f(dayKey(d));
        },
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), side: const BorderSide(color: C.line), foregroundColor: v.isEmpty ? C.mute : C.ink),
        child: Text(v.isEmpty ? hint : v, overflow: TextOverflow.ellipsis),
      );

  /* 2: invoices */
  Widget _invoices() {
    final inv = p.lst('inv');
    final vt = double.tryParse(ivt.text.replaceAll(',', '.')) ?? 0;
    final dc = invCalc(draft, vt);
    if (idu.isEmpty) idu = dAdd(idt, 7);
    final il = inv.toList()..sort((a, b) => '${b['date']}'.compareTo('${a['date']}') != 0 ? '${b['date']}'.compareTo('${a['date']}') : '${b['no']}'.compareTo('${a['no']}'));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      uCard('Yangi hisob-faktura', children: [
        uField(icl, 'Mijoz nomi', max: 40),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _dateBtn(idt, (d) => setState(() => idt = d), hint: 'Sana')),
          const SizedBox(width: 8),
          Expanded(child: _dateBtn(idu, (d) => setState(() => idu = d), hint: "To'lov muddati")),
        ]),
        const SizedBox(height: 8),
        uField(ivt, 'QQS % (ixtiyoriy)', num: true, onChanged: (_) => setState(() {})),
        const SizedBox(height: 10),
        const Text('Qatorlar', style: TextStyle(color: C.dim, fontWeight: FontWeight.w700, fontSize: 12.5)),
        const SizedBox(height: 6),
        if (draft.isEmpty) uSmall("Hali qator yo'q."),
        for (var k = 0; k < draft.length; k++)
          URow(title: '${draft[k]['n']}', sub: '${draft[k]['q']} × ${mny(draft[k]['p'] as num)}', amount: mny((draft[k]['q'] as num) * (draft[k]['p'] as num)), action: IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.close_rounded, size: 18, color: C.out), onPressed: () => setState(() => draft.removeAt(k)))),
        if (draft.isNotEmpty) uSmall('Jami: ${mny(dc.sub)}${dc.vat > 0 ? ' + QQS ${mny(dc.vat)} = ${mny(dc.tot)}' : ''}'),
        uField(iin, 'Mahsulot yoki xizmat nomi', max: 60),
        const SizedBox(height: 8),
        Row(children: [Expanded(child: uField(iiq, 'Soni', num: true)), const SizedBox(width: 8), Expanded(child: uField(iip, 'Narxi', num: true))]),
        const SizedBox(height: 10),
        uBtn("Qatorni qo'shish", () {
          if (_addLine() case final String err) _msg(err);
        }, ghost: true),
        const SizedBox(height: 8),
        uBtn('Hisob-faktura yaratish', _createInv),
      ]),
      uCard('Hisob-fakturalar', sub: '${inv.length} ta', children: [
        if (il.isEmpty) uSmall("Hali hisob-faktura yo'q."),
        for (final v in il) _invRow(v),
      ]),
    ]);
  }

  String? _addLine() {
    final nm = iin.text.trim();
    final q = parseAmount(iiq.text.trim().isEmpty ? '1' : iiq.text);
    final pr = parseAmount(iip.text);
    if (nm.length < 2) return 'Mahsulot yoki xizmat nomini kiriting.';
    if (q == null || q <= 0) return 'Sonini kiriting.';
    if (iip.text.trim().isEmpty || pr == null || pr < 0) return 'Narxni kiriting.';
    if (draft.length >= 30) return "Eng ko'pi 30 qator.";
    setState(() {
      draft.add({'n': nm.length > 60 ? nm.substring(0, 60) : nm, 'q': q, 'p': fixAmt(pr)});
      iin.clear();
      iip.clear();
      iiq.text = '1';
    });
    return null;
  }

  Future<void> _createInv() async {
    // include a half-typed line, like the web version
    if (iin.text.trim().isNotEmpty && iip.text.trim().isNotEmpty) {
      final q = parseAmount(iiq.text.trim().isEmpty ? '1' : iiq.text), pr = parseAmount(iip.text);
      if (q != null && q > 0 && pr != null && pr >= 0 && iin.text.trim().length >= 2) {
        draft.add({'n': iin.text.trim(), 'q': q, 'p': fixAmt(pr)});
        iin.clear();
        iip.clear();
      }
    }
    final cl = icl.text.trim();
    final vt = ivt.text.trim().isEmpty ? 0.0 : (double.tryParse(ivt.text.trim().replaceAll(',', '.')) ?? -1);
    if (cl.length < 2) return _msg('Mijoz nomini kiriting.');
    if (draft.isEmpty) return _msg("Kamida bitta qator qo'shing.");
    if (idu.isNotEmpty && idu.compareTo(idt) < 0) return _msg("To'lov muddati sanadan oldin bo'lmasin.");
    if (!(vt >= 0 && vt <= 100)) return _msg('QQS 0 dan 100 gacha bo\'lsin.');
    var mxn = 0;
    for (final x in p.lst('inv')) {
      final k = int.tryParse('${x['no']}'.length > 4 ? '${x['no']}'.substring(4) : '') ?? 0;
      if (k > mxn) mxn = k;
    }
    final ct = invCalc(draft, vt);
    p.lst('inv').add({'id': nid(), 'no': 'INV-${(mxn + 1).toString().padLeft(4, '0')}', 'client': cl, 'date': idt, 'due': idu, 'items': draft.map((e) => Map<String, dynamic>.from(e)).toList(), 'vat': vt, 'total': ct.tot, 'paid': 0, 'paidAt': ''});
    draft.clear();
    icl.clear();
    ivt.clear();
    idt = todayStr();
    idu = '';
    await _done('Hisob-faktura yaratildi');
  }

  Widget _invRow(Map<String, dynamic> v) {
    final st = invSt(v);
    final total = ((v['total'] ?? 0) as num).toDouble(), paid = ((v['paid'] ?? 0) as num).toDouble();
    final qd = fixAmt(total - paid);
    final id = '${v['id']}';
    final pc = payC.putIfAbsent(id, () => TextEditingController());
    final due = '${v['due'] ?? ''}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color(0x08FFFFFF), border: Border.all(color: st == 'late' ? C.out.withOpacity(.4) : C.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${v['no']} · ${v['client']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
              Text.rich(TextSpan(style: const TextStyle(color: C.dim, fontSize: 12.5), children: [
                TextSpan(text: '${v['date']}${due.isNotEmpty ? ' · muddati $due' : ''} · '),
                TextSpan(text: kInvL[st], style: TextStyle(color: st == 'paid' ? C.accent : st == 'late' ? C.out : C.dim)),
                if (paid > 0 && st != 'paid') TextSpan(text: " · to'langan ${mny(paid)}"),
              ])),
            ]),
          ),
          Text(mny(total), style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          if (st != 'paid') ...[
            Expanded(child: SizedBox(height: 38, child: TextField(controller: pc, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(fontSize: 13), decoration: InputDecoration(hintText: 'Summa (${mny(qd)})', isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8))))),
            TextButton(
              onPressed: () async {
                final due0 = qd;
                final am = pc.text.trim().isEmpty ? due0 : parseAmount(pc.text);
                if (am == null || am <= 0) return _msg("Summani to'g'ri kiriting.");
                if (am > due0 + .001) return _msg('Summa qarzdan oshmasin: ${mny(due0)}');
                final ta0 = fixAmt(am);
                final nn = 'Hisob-faktura ${v['no']} · ${v['client']}';
                await app.addTx(Tx(id: newId(), t: 'in', a: ta0, c: 'b_sale', n: nn.length > 60 ? nn.substring(0, 60) : nn, d: todayStr(), ts: DateTime.now().millisecondsSinceEpoch, ex: {'b': 1}));
                var np = r2(paid + ta0);
                if (np > total) np = total;
                v['paid'] = np;
                v['paidAt'] = todayStr();
                pc.clear();
                await _done("To'lov qabul qilindi: +${grp(ta0)} ${curUnit()}");
              },
              child: const Text("To'lov qabul qilish", style: TextStyle(color: C.accent, fontWeight: FontWeight.w700, fontSize: 12.5)),
            ),
          ] else
            const Spacer(),
          TextButton(onPressed: () => _copy(invText(v)), child: const Text('Nusxa', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5))),
          SureBtn(onSure: () {
            p.x['inv'] = p.lst('inv').where((y) => y['id'] != v['id']).toList();
            _done("O'chirildi");
          }),
        ]),
      ]),
    );
  }

  /* 3: clients */
  Widget _clients() {
    final cm = <String, Map<String, dynamic>>{};
    for (final v in p.lst('inv')) {
      final k = '${v['client']}'.trim().toLowerCase();
      final o = cm.putIfAbsent(k, () => {'name': '${v['client']}'.trim(), 'n': 0, 'tot': 0.0, 'paid': 0.0, 'late': 0});
      o['n'] = (o['n'] as int) + 1;
      o['tot'] = (o['tot'] as double) + ((v['total'] ?? 0) as num);
      o['paid'] = (o['paid'] as double) + ((v['paid'] ?? 0) as num);
      if (invSt(v) == 'late') o['late'] = (o['late'] as int) + 1;
    }
    final cr = cm.values.toList()..sort((a, b) => ((b['tot'] as double) - (b['paid'] as double)).compareTo((a['tot'] as double) - (a['paid'] as double)));
    var cdue = 0.0;
    for (final c in cr) {
      cdue += (c['tot'] as double) - (c['paid'] as double);
    }
    return uCard('Mijozlar daftari', sub: 'Kutilmoqda: ${mny(cdue)}', children: [
      if (cr.isEmpty) uSmall('Mijozlar hisob-fakturalardan avtomatik shakllanadi.'),
      for (final c in cr)
        Builder(builder: (_) {
          final d = fixAmt((c['tot'] as double) - (c['paid'] as double));
          final late = c['late'] as int;
          return URow(title: '${c['name']}', sub: "${c['n']} ta hisob-faktura · jami ${mny(c['tot'] as double)} · to'lagan ${mny(c['paid'] as double)}${late > 0 ? " · muddati o'tgan: $late ta" : ''}", amount: d > 0 ? '${mny(d)}\nqarz' : '✓', late: late > 0);
        }),
    ]);
  }

  /* 4: tax */
  Widget _tax() {
    final tl = p.lst('bizTax');
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      uCard('Soliq stavkasi', children: [
        uSmall("Tushumdan taxminiy soliq hisoblash uchun stavkani o'zingiz kiriting. Bu rasmiy hisob emas, faqat taxminiy ko'rsatkich."),
        uField(trc, 'Soliq stavkasi, %', num: true),
        const SizedBox(height: 10),
        uBtn('Saqlash', () {
          final r = trc.text.trim().isEmpty ? 0.0 : parseAmount(trc.text);
          if (r == null || r < 0 || r > 100) return _msg("Stavka 0 dan 100 gacha bo'lsin.");
          p.mp('biz')['taxRate'] = r;
          _done('Saqlandi');
        }),
      ]),
      uCard("Soliq va to'lov muddatlari", children: [
        if (tl.isEmpty) uSmall("Soliq, ijara yoki boshqa majburiy to'lov muddatlarini qo'shing, 3 kun oldin eslatamiz."),
        for (final x in tl)
          Builder(builder: (_) {
            final m = x['kind'] == 'm';
            final d = m ? daysTo(((x['day'] ?? 1) as num).toInt()) : dueIn('${x['date']}');
            return URow(title: '${x['name']}', sub: '${m ? 'Har oy ${x['day']}-kuni' : x['date']} · ${d < 0 ? "muddati o'tgan" : d > 0 ? '$d kun qoldi' : 'bugun'}', amount: ((x['amt'] ?? 0) as num) > 0 ? mny(x['amt'] as num) : '', late: d <= 3, action: SureBtn(onSure: () {
              p.x['bizTax'] = tl.where((y) => y['id'] != x['id']).toList();
              _done();
            }));
          }),
        uField(tn, "Nomi (Soliq to'lovi)", max: 40),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: tk,
              isExpanded: true,
              dropdownColor: C.bg2,
              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
              items: const [DropdownMenuItem(value: 'm', child: Text('Har oy')), DropdownMenuItem(value: 'o', child: Text('Bir marta'))],
              onChanged: (v) => setState(() => tk = v ?? tk),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: uField(ta, 'Summa (ixtiyoriy)', num: true)),
        ]),
        const SizedBox(height: 8),
        if (tk == 'm') uField(td, 'Oyning kuni (1-31)', kt: TextInputType.number) else _dateBtn(tdt, (d) => setState(() => tdt = d), hint: 'Sanani tanlang'),
        const SizedBox(height: 10),
        uBtn("Qo'shish", () {
          final nm = tn.text.trim();
          final am = ta.text.trim().isEmpty ? 0.0 : parseAmount(ta.text);
          final dy = parseAmount(td.text)?.round();
          if (nm.length < 2) return _msg('Nomini kiriting.');
          if (am == null || am < 0) return _msg('Summani raqam bilan kiriting.');
          if (tk == 'm' && (dy == null || dy < 1 || dy > 31)) return _msg("Kun 1 dan 31 gacha bo'lsin.");
          if (tk == 'o' && tdt.isEmpty) return _msg('Sanani kiriting.');
          tl.add({'id': nid(), 'name': nm, 'kind': tk, 'day': dy ?? 0, 'date': tdt, 'amt': am});
          tn.clear();
          ta.clear();
          td.clear();
          tdt = '';
          _done("Qo'shildi");
        }),
      ]),
    ]);
  }

  /* 5: settings */
  Widget _settings() => uCard("Biznes ma'lumotlari", children: [
        uSmall("Hisob-faktura va hisobotlarda ko'rinadi."),
        uField(bnm, 'Biznes nomi', max: 50),
        const SizedBox(height: 8),
        Row(children: [Expanded(child: uField(bi, 'STIR', max: 20)), const SizedBox(width: 8), Expanded(child: uField(bp, 'Telefon', max: 20))]),
        const SizedBox(height: 8),
        uField(bq, "To'lov rekvizitlari (hisob raqami yoki karta)", max: 120),
        const SizedBox(height: 10),
        uBtn('Saqlash', () {
          final B = p.mp('biz');
          B['name'] = bnm.text.trim();
          B['inn'] = bi.text.trim();
          B['phone'] = bp.text.trim();
          B['req'] = bq.text.trim();
          _done('Saqlandi');
        }),
      ]);
}

void bizRemind(BuildContext context) {
  final p = app.profile;
  if (p == null || !p.isBiz) return;
  final m = <String>[];
  var n = 0;
  for (final x in p.lst('bizTax')) {
    final d = x['kind'] == 'm' ? daysTo(((x['day'] ?? 1) as num).toInt()) : dueIn('${x['date']}');
    if (d <= 3) m.add('${x['name']}${d < 0 ? " (muddati o'tgan)" : d > 0 ? ' ($d kun)' : ' (bugun)'}');
  }
  for (final v in p.lst('inv')) {
    final due = '${v['due'] ?? ''}';
    if (invSt(v) != 'paid' && due.isNotEmpty && dueIn(due) <= 3) n++;
  }
  if (n > 0) m.add("$n ta hisob-faktura muddati yaqin yoki o'tgan");
  if (m.isNotEmpty) toast(context, 'Biznes: ${m.take(3).join(', ')}');
}

/* ====================================================================== */
/*  OILA: family budget (device-local store, same as the web fallback)     */
/* ====================================================================== */
const int kFamMax = 5;
const List<Color> kFamC = [Color(0xFFE11D48), Color(0xFF7C3AED), Color(0xFF0D9488), Color(0xFFEA580C), Color(0xFF2563EB)];

String rndId(int n) {
  const a = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';
  final r = math.Random.secure();
  return List.generate(n, (_) => a[r.nextInt(a.length)]).join();
}

String normFid(String v) {
  final s = v.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
  return RegExp(r'^[A-Z0-9][A-Z0-9_-]{4,22}[A-Z0-9]$').hasMatch(s) ? s : '';
}

String famUid() {
  final p = app.profile!;
  var u = '${p.x['uid'] ?? ''}';
  if (u.isEmpty) {
    u = 'u${rndId(12).toLowerCase()}';
    p.x['uid'] = u;
    app.saveProfile();
  }
  return u;
}

/// Local family store (prefs key "hamyon-fam-<id>"), mirrors FS in the web app.
class FamStore {
  static Map<String, dynamic>? read(String id) {
    try {
      final s = app.prefs.getString('hamyon-fam-$id');
      if (s == null) return null;
      final o = jsonDecode(s);
      if (o is Map) return Map<String, dynamic>.from(o);
    } catch (_) {}
    return null;
  }

  static Future<void> write(String id, Map<String, dynamic> o) => app.prefs.setString('hamyon-fam-$id', jsonEncode(o));

  static Map<String, dynamic> col(Map<String, dynamic> o, String c) {
    final v = o[c];
    if (v is Map) return Map<String, dynamic>.from(v);
    return {};
  }

  static Future<void> put(String id, String c, String key, Map<String, dynamic> d) async {
    final o = read(id);
    if (o == null) throw StateError('yoq');
    final m = col(o, c);
    m[key] = d;
    o[c] = m;
    await write(id, o);
  }

  static Future<void> upd(String id, String c, String key, Map<String, dynamic> d) async {
    final o = read(id);
    if (o == null) return;
    final m = col(o, c);
    if (m[key] is! Map) return;
    m[key] = {...Map<String, dynamic>.from(m[key] as Map), ...d};
    o[c] = m;
    await write(id, o);
  }

  static Future<void> del(String id, String c, String key) async {
    final o = read(id);
    if (o == null) return;
    final m = col(o, c);
    m.remove(key);
    o[c] = m;
    await write(id, o);
  }

  static Future<void> patchDoc(String id, Map<String, dynamic> d) async {
    final o = read(id);
    if (o == null) return;
    o['doc'] = {...Map<String, dynamic>.from(o['doc'] as Map), ...d};
    await write(id, o);
  }

  static List<Map<String, dynamic>> list(Map<String, dynamic> o, String c) =>
      col(o, c).entries.map((e) => {...Map<String, dynamic>.from(e.value as Map), 'id': e.key}).toList();
}

String fmRole(String r) => r == 'owner' ? 'Boshliq' : r == 'child' ? 'Bola' : "A'zo";

class OilaTab extends StatefulWidget {
  final ShellApi api;
  const OilaTab({super.key, required this.api});
  @override
  State<OilaTab> createState() => _OilaTabState();
}

class _OilaTabState extends State<OilaTab> {
  int _tab = 0;
  String mk = monthKeyOf(DateTime.now());
  Profile get p => app.profile!;
  static const _groups = ['Umumiy', 'Xarajatlar', 'Maqsadlar', 'Tahlil'];

  final fn = TextEditingController(), fid = TextEditingController(text: 'OILA-${rndId(6)}');
  final jn = TextEditingController(), jid = TextEditingController();
  final fa = TextEditingController(), fnt = TextEditingController(), flim = TextEditingController();
  final gn = TextEditingController(), ga = TextEditingController();
  final Map<String, TextEditingController> gc = {}, pk = {};
  String fType = 'out', fCat = 'food', fDate = todayStr();
  String? err;

  void _msg(String m) => toast(context, m);
  void _re() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [fn, fid, jn, jid, fa, fnt, flim, gn, ga, ...gc.values, ...pk.values]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _leave(String msg) async {
    p.x['fam'] = null;
    p.plan = 'free';
    p.maxUntil = 0;
    await app.saveProfile();
    if (!mounted) return;
    widget.api.show('home');
    toast(context, msg);
  }

  Future<void> _run(Future<void> Function() f) async {
    try {
      await f();
      _re();
    } catch (_) {
      if (mounted) _msg("Bazaga yozib bo'lmadi. Keyinroq urinib ko'ring.");
    }
  }

  Future<String> _create(String id, String name) async {
    final uid = famUid();
    if (FamStore.read(id) != null) return 'Bu ID band. Boshqasini tanlang.';
    await FamStore.write(id, {
      'doc': {'name': name, 'owner': uid, 'ownerName': p.name, 'until': p.maxUntil, 'created': DateTime.now().millisecondsSinceEpoch, 'limit': 0},
      'members': {uid: {'name': p.name, 'role': 'owner', 'pocket': 0, 'joined': DateTime.now().millisecondsSinceEpoch}},
      'tx': {},
      'goals': {},
      'gc': {},
    });
    p.x['fam'] = {'id': id, 'role': 'owner'};
    await app.saveProfile();
    return '';
  }

  Future<String> _join(String raw, String name) async {
    final id = normFid(raw);
    if (id.isEmpty) return "ID noto'g'ri. Harf, raqam va chiziqchadan iborat 6–24 belgi.";
    if (name.length < 2) return 'Ismingizni kiriting (kamida 2 harf).';
    final uid = famUid();
    final o = FamStore.read(id);
    if (o == null || o['doc'] is! Map) return 'Bunday oila ID topilmadi (bu qurilmada).';
    final doc = Map<String, dynamic>.from(o['doc'] as Map);
    if (!(((doc['until'] ?? 0) as num) > DateTime.now().millisecondsSinceEpoch)) return 'Bu oilaning tarifi muddati tugagan.';
    final ms = FamStore.list(o, 'members');
    final mine = ms.where((m) => m['id'] == uid).toList();
    if (mine.isEmpty && ms.length >= kFamMax) return 'Oilada joy qolmagan ($kFamMax / $kFamMax).';
    if (mine.isEmpty) await FamStore.put(id, 'members', uid, {'name': name, 'role': 'member', 'pocket': 0, 'joined': DateTime.now().millisecondsSinceEpoch});
    p.plan = 'oila';
    p.maxUntil = ((doc['until'] ?? 0) as num).toInt();
    p.x['fam'] = {'id': id, 'role': mine.isEmpty ? 'member' : mine.first['role']};
    await app.saveProfile();
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (!p.isFam) {
      return ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Oila', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Oila tarifi yoqilmagan.', style: TextStyle(color: C.dim)),
        const SizedBox(height: 16),
        PrimaryButton(label: "Oila ga o'tish", onTap: () => widget.api.show('plans')),
      ]);
    }
    final uid = famUid();
    final fam = p.x['fam'];
    if (fam is! Map) return _noFamily();
    final id = '${fam['id']}';
    final o = FamStore.read(id);
    if (o == null || o['doc'] is! Map) {
      return ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Oila', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text("Oila ma'lumotlarini o'qib bo'lmadi.", style: TextStyle(color: C.dim)),
        const SizedBox(height: 12),
        uBtn('Oiladan chiqish', () => _leave('Free tarifga o\'tdingiz.'), ghost: true),
      ]);
    }
    final D = Map<String, dynamic>.from(o['doc'] as Map);
    final members = FamStore.list(o, 'members');
    final txs = FamStore.list(o, 'tx')..sort((a, b) => ((b['ts'] ?? 0) as num).compareTo((a['ts'] ?? 0) as num));
    final goals = FamStore.list(o, 'goals');
    final gcs = FamStore.list(o, 'gc');
    // sync role from store
    final me = members.where((m) => m['id'] == uid).toList();
    var role = '${fam['role']}';
    if (me.isNotEmpty && role != 'owner' && me.first['role'] != role) {
      role = '${me.first['role']}';
      fam['role'] = role;
      app.saveProfile();
    }
    if (role != 'owner' && members.isNotEmpty && me.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _leave("Siz oiladan chiqarildingiz. Free tarifga o'tdingiz."));
    }
    final own = role == 'owner';
    final st = (id: id, D: D, members: members, txs: txs, goals: goals, gcs: gcs, role: role, own: own, uid: uid, me: me.isEmpty ? <String, dynamic>{} : me.first);
    final tabs = [_general(st), _spend(st), _goals(st), _analysis(st)];
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
      const Text('Oila', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      Text('${D['name'] ?? 'Oilaviy byudjet'}', style: const TextStyle(color: C.dim, fontSize: 13.5)),
      const SizedBox(height: 12),
      SizedBox(
        height: 40,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (var i = 0; i < _groups.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_groups[i]),
                selected: _tab == i,
                onSelected: (_) => setState(() => _tab = i),
                selectedColor: C.accent.withOpacity(.2),
                backgroundColor: const Color(0x0AFFFFFF),
                side: BorderSide(color: _tab == i ? C.accent : C.line),
                labelStyle: TextStyle(color: _tab == i ? Colors.white : C.dim, fontWeight: FontWeight.w700),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 14),
      tabs[_tab],
    ]);
  }

  Widget _noFamily() => ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
        const Text('Oila', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const Text("Oilangiz uchun umumiy byudjet. A'zolar sizning ID ingiz bilan kiradi.", style: TextStyle(color: C.dim, fontSize: 13.5)),
        const SizedBox(height: 14),
        uCard('Oilani yaratish', children: [
          uField(fn, 'Oila nomi (Karimovlar oilasi)', max: 40),
          const SizedBox(height: 8),
          uField(fid, 'Oila ID', max: 24),
          uSmall("Tayyor ID taklif qilindi, istasangiz o'zingiznikini yozing (6–24 belgi: harf, raqam, chiziqcha). A'zolarga shu ID ni berasiz."),
          if (err != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: MsgBox(err!)),
          uBtn('Oilani yaratish', () async {
            final nm = fn.text.trim();
            final id = normFid(fid.text);
            if (nm.length < 2) return setState(() => err = 'Oila nomini kiriting.');
            if (id.isEmpty) return setState(() => err = "ID noto'g'ri: 6–24 belgi, harf, raqam yoki chiziqcha.");
            try {
              final r = await _create(id, nm);
              if (r.isNotEmpty) return setState(() => err = r);
              err = null;
              _re();
              if (mounted) _msg('Oila yaratildi');
            } catch (_) {
              setState(() => err = "Bazaga yozib bo'lmadi. Keyinroq urinib ko'ring.");
            }
          }),
        ]),
        uCard("Boshqa oilaga qo'shilish", children: [
          uSmall("Oila boshlig'i bergan ID bo'lsa, shu yerdan kiring. Eslatma: oila ma'lumotlari shu qurilmada saqlanadi, shu sababli faqat shu qurilmada yaratilgan oilaga qo'shilish mumkin."),
          uField(jid, 'Oila ID', max: 24),
          const SizedBox(height: 8),
          uField(jn, 'Ismingiz', max: 40),
          const SizedBox(height: 10),
          uBtn('Oila ID bilan kirish', () async {
            final r = await _join(jid.text, jn.text.trim().isEmpty ? p.name : jn.text.trim());
            if (r.isNotEmpty) return _msg(r);
            _re();
            if (mounted) _msg("Oilaga qo'shildingiz");
          }, ghost: true),
        ]),
      ]);

  Color _col(List<Map<String, dynamic>> ms, String? uid) {
    var i = 0;
    for (var k = 0; k < ms.length; k++) {
      if (ms[k]['id'] == uid) i = k;
    }
    return kFamC[i % kFamC.length];
  }

  String _nm(List<Map<String, dynamic>> ms, String? uid, [String fb = 'Chiqib ketgan']) {
    for (final m in ms) {
      if (m['id'] == uid) return '${m['name']}';
    }
    return fb;
  }

  Widget _av(List<Map<String, dynamic>> ms, String? uid, String name) => Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: _col(ms, uid)),
        child: Text(name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
      );

  Widget _mon() => Center(child: MonthBar(mk: mk, onShift: (d) {
        final pp = mk.split('-');
        final nk = monthKeyOf(DateTime(int.parse(pp[0]), int.parse(pp[1]) + d, 1));
        if (nk.compareTo(monthKeyOf(DateTime.now())) > 0) return;
        setState(() => mk = nk);
      }));

  List<Map<String, dynamic>> _mtx(List<Map<String, dynamic>> txs, String k) => txs.where((x) => '${x['d'] ?? ''}'.length >= 7 && '${x['d']}'.substring(0, 7) == k).toList();

  /* 0: general */
  Widget _general(dynamic st) {
    final D = st.D as Map<String, dynamic>;
    final ms = st.members as List<Map<String, dynamic>>;
    final left = math.max(0, ((((D['until'] ?? 0) as num) - DateTime.now().millisecondsSinceEpoch) / 864e5).ceil());
    final sorted = ms.toList()..sort((a, b) {
      final c = (a['role'] == 'owner' ? 0 : 1).compareTo(b['role'] == 'owner' ? 0 : 1);
      return c != 0 ? c : ((a['joined'] ?? 0) as num).compareTo((b['joined'] ?? 0) as num);
    });
    final own = st.own as bool;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      uCard('${D['name'] ?? 'Oila'}', sub: "${ms.length} / $kFamMax a'zo", children: [
        URow(title: 'Oila ID', sub: "Faqat oila a'zolariga bering\n${st.id}", action: TextButton(onPressed: () async {
          await Clipboard.setData(ClipboardData(text: st.id as String));
          if (mounted) _msg('Oila ID nusxalandi');
        }, child: const Text('Nusxa'))),
        URow(title: 'Tarif muddati', sub: "Oila boshlig'i to'lovi bo'yicha", amount: '$left kun'),
        const NoteBox("Umumiy baza ulanmagan: oila ma'lumotlari faqat shu qurilmada saqlanadi."),
      ]),
      uCard("A'zolar", children: [
        for (final m in sorted)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color(0x08FFFFFF), border: Border.all(color: C.line)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                _av(ms, '${m['id']}', '${m['name'] ?? '?'}'),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${m['name'] ?? "A'zo"}${m['id'] == st.uid ? ' (siz)' : ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(fmRole('${m['role']}'), style: TextStyle(color: m['role'] == 'owner' ? C.warn : C.dim, fontSize: 12, fontWeight: FontWeight.w700)),
                    if (m['role'] == 'child' && ((m['pocket'] ?? 0) as num) > 0) Text("Oylik cho'ntak puli: ${mny(m['pocket'] as num)}", style: const TextStyle(color: C.dim, fontSize: 12)),
                  ]),
                ),
              ]),
              if (own && m['role'] != 'owner')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(children: [
                    SizedBox(
                      width: 104,
                      child: DropdownButtonFormField<String>(
                        value: m['role'] == 'child' ? 'child' : 'member',
                        isExpanded: true,
                        dropdownColor: C.bg2,
                        decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                        items: const [DropdownMenuItem(value: 'member', child: Text("A'zo")), DropdownMenuItem(value: 'child', child: Text('Bola'))],
                        onChanged: (v) => _run(() => FamStore.upd(st.id as String, 'members', '${m['id']}', {'role': v == 'child' ? 'child' : 'member'})),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (m['role'] == 'child')
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: TextField(
                            controller: pk.putIfAbsent('${m['id']}', () => TextEditingController(text: ((m['pocket'] ?? 0) as num) > 0 ? '${m['pocket']}' : '')),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(hintText: 'Limit', isDense: true),
                            onSubmitted: (v) {
                              final x = v.trim().isEmpty ? 0.0 : parseAmount(v);
                              if (x == null || x < 0 || x > 1e12) return _msg('Limitni raqam bilan kiriting.');
                              _run(() async {
                                await FamStore.upd(st.id as String, 'members', '${m['id']}', {'pocket': x});
                                _msg("Cho'ntak puli saqlandi");
                              });
                            },
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    SureBtn(label: 'Chiqarish', onSure: () => _run(() async {
                      await FamStore.del(st.id as String, 'members', '${m['id']}');
                      _msg("A'zo oiladan chiqarildi");
                    })),
                  ]),
                ),
            ]),
          ),
        if (!own) SizedBox(width: double.infinity, child: uBtn('Oiladan chiqish', () => _leaveSure(st), ghost: true)) else uSmall("Bola roli: bola faqat chiqim qo'sha oladi va maqsad yarata olmaydi. Cho'ntak puli limiti oy bo'yicha hisoblanadi (limitni kiritib, klaviaturada «tayyor» ni bosing)."),
      ]),
    ]);
  }

  Future<void> _leaveSure(dynamic st) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: C.bg2,
        title: const Text('Oiladan chiqasizmi?'),
        content: const Text("Free tarifga o'tasiz."),
        actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Yo\'q')), TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Chiqish', style: TextStyle(color: C.out)))],
      ),
    );
    if (ok != true) return;
    try {
      await FamStore.del(st.id as String, 'members', st.uid as String);
      await _leave("Oiladan chiqdingiz. Free tarifga o'tdingiz.");
    } catch (_) {
      if (mounted) _msg("Bazaga yozib bo'lmadi.");
    }
  }

  /* 1: spending */
  Widget _spend(dynamic st) {
    final ms = st.members as List<Map<String, dynamic>>;
    final role = st.role as String;
    final mtx = _mtx(st.txs as List<Map<String, dynamic>>, mk);
    var ti = 0.0, to = 0.0;
    for (final x in mtx) {
      final a = ((x['a'] ?? 0) as num).toDouble();
      if (x['t'] == 'in') {
        ti += a;
      } else {
        to += a;
      }
    }
    final me0 = st.me as Map<String, dynamic>;
    final cats = catsOf('out');
    if (!cats.any((c) => c.id == fCat)) fCat = cats.first.id;
    if (role == 'child') fType = 'out';
    var used = 0.0;
    if (role == 'child' && ((me0['pocket'] ?? 0) as num) > 0) {
      for (final x in _mtx(st.txs as List<Map<String, dynamic>>, monthKeyOf(DateTime.now()))) {
        if (x['t'] == 'out' && x['by'] == st.uid) used += ((x['a'] ?? 0) as num).toDouble();
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _mon(),
      Row(children: [
        _kpiBox('Kirim', mny(ti), 'Oila kirimi'),
        _kpiBox('Chiqim', mny(to), 'Oila chiqimi'),
        _kpiBox('Farq', '${ti - to < 0 ? '−' : ''}${mny((ti - to).abs())}', 'Qoldi'),
      ]),
      const SizedBox(height: 14),
      uCard('Oila operatsiyasi', children: [
        if (role == 'child' && ((me0['pocket'] ?? 0) as num) > 0) NoteBox("Cho'ntak pulingiz: ${mny(math.max(0, ((me0['pocket'] as num) - used).toDouble()))} qoldi (limit ${mny(me0['pocket'] as num)})."),
        Row(children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: fType,
              isExpanded: true,
              dropdownColor: C.bg2,
              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
              items: [const DropdownMenuItem(value: 'out', child: Text('Chiqim')), if (role != 'child') const DropdownMenuItem(value: 'in', child: Text('Kirim'))],
              onChanged: role == 'child' ? null : (v) => setState(() => fType = v ?? fType),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: uField(fa, 'Summa', num: true)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: fCat,
              isExpanded: true,
              dropdownColor: C.bg2,
              decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
              items: [for (final c in cats) DropdownMenuItem(value: c.id, child: Text(c.name, overflow: TextOverflow.ellipsis))],
              onChanged: (v) => setState(() => fCat = v ?? fCat),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                final d = await showDatePicker(context: context, initialDate: parseDay(fDate), firstDate: DateTime(2000), lastDate: DateTime(2100));
                if (d != null) setState(() => fDate = dayKey(d));
              },
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), side: const BorderSide(color: C.line), foregroundColor: C.ink),
              child: Text(fDate),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        uField(fnt, 'Izoh (ixtiyoriy)', max: 60),
        const SizedBox(height: 10),
        uBtn("Qo'shish", () {
          final v = parseAmount(fa.text);
          if (v == null || v <= 0 || v > 1e12) return _msg("Summani to'g'ri kiriting.");
          final isIn = role != 'child' && fType == 'in';
          final c = isIn ? catsOf('in').last.id : fCat;
          _run(() async {
            await FamStore.put(st.id as String, 'tx', nid(), {'t': isIn ? 'in' : 'out', 'a': fixAmt(v), 'c': c, 'n': fnt.text.trim(), 'd': fDate, 'ts': DateTime.now().millisecondsSinceEpoch, 'by': st.uid, 'byName': p.name});
            fa.clear();
            fnt.clear();
            _msg("Oilaga qo'shildi");
          });
        }),
      ]),
      uCard('Operatsiyalar', children: [
        if (mtx.isEmpty) uSmall("Bu oyda oila operatsiyalari yo'q."),
        for (final x in mtx.take(80))
          Builder(builder: (_) {
            final c = catOf(x['t'] == 'in' ? 'in' : 'out', '${x['c']}');
            final can = st.own == true || x['by'] == st.uid;
            final inc = x['t'] == 'in';
            return URow(
              title: '${c.name}${'${x['n'] ?? ''}'.isNotEmpty ? ' · ${x['n']}' : ''}',
              sub: '${_nm(ms, x['by'] as String?, '${x['byName'] ?? 'Chiqib ketgan'}')} · ${x['d']}',
              amount: '${inc ? '+' : '−'}${mny(x['a'] as num)}',
              amountColor: inc ? C.accent : C.out,
              action: can ? IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.close_rounded, size: 18, color: C.out), onPressed: () => _run(() => FamStore.del(st.id as String, 'tx', '${x['id']}'))) : null,
            );
          }),
      ]),
    ]);
  }

  Widget _kpiBox(String k, String v, String s) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.all(10),
          decoration: _glass(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(k, style: const TextStyle(color: C.dim, fontSize: 11.5)),
            const SizedBox(height: 4),
            FittedBox(fit: BoxFit.scaleDown, child: Text(v, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
            Text(s, style: const TextStyle(color: C.mute, fontSize: 11)),
          ]),
        ),
      );

  /* 2: goals */
  Widget _goals(dynamic st) {
    final ms = st.members as List<Map<String, dynamic>>;
    final goals = (st.goals as List<Map<String, dynamic>>).toList()..sort((a, b) => ((a['ts'] ?? 0) as num).compareTo((b['ts'] ?? 0) as num));
    final gcs = st.gcs as List<Map<String, dynamic>>;
    final id = st.id as String;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      uCard('Umumiy maqsadlar', children: [
        if (goals.isEmpty) uSmall("Hali maqsad yo'q. Masalan: to'y, mashina, ta'til."),
        for (final g in goals)
          Builder(builder: (_) {
            var sv = 0.0;
            final by = <String, double>{};
            for (final c in gcs) {
              if (c['goal'] == g['id']) {
                final a = ((c['a'] ?? 0) as num).toDouble();
                sv += a;
                by['${c['by']}'] = (by['${c['by']}'] ?? 0) + a;
              }
            }
            final target = ((g['target'] ?? 0) as num).toDouble();
            final pc = target > 0 ? math.min(100, (sv / target * 100).round()) : 0;
            final parts = by.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
            final ctrl = gc.putIfAbsent('${g['id']}', () => TextEditingController());
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: C.line))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Expanded(child: Text('${g['name']}', style: const TextStyle(fontWeight: FontWeight.w800))), Text('$pc%', style: const TextStyle(fontWeight: FontWeight.w800))]),
                const SizedBox(height: 6),
                uBar(pc / 100, pc >= 100 ? C.accent : C.accent2),
                const SizedBox(height: 4),
                Text('${mny(sv)} / ${mny(target)}${pc >= 100 ? ' · Erishildi' : ''}', style: const TextStyle(color: C.dim, fontSize: 12.5)),
                if (parts.isNotEmpty) Text('Hissalar: ${parts.map((e) => '${_nm(ms, e.key)} ${mny(e.value)}').join(' · ')}', style: const TextStyle(color: C.dim, fontSize: 12.5)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: SizedBox(height: 42, child: TextField(controller: ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(hintText: 'Hissa summasi', isDense: true)))),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: C.accent, foregroundColor: const Color(0xFF02130D), minimumSize: const Size(0, 42)),
                    onPressed: () {
                      final c = parseAmount(ctrl.text);
                      if (c == null || c <= 0 || c > 1e12) return _msg('Hissa summasini kiriting.');
                      _run(() async {
                        await FamStore.put(id, 'gc', nid(), {'goal': g['id'], 'a': fixAmt(c), 'by': st.uid, 'ts': DateTime.now().millisecondsSinceEpoch});
                        ctrl.clear();
                        _msg("Hissa qo'shildi");
                      });
                    },
                    child: const Text("Hissa qo'shish", style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  if (st.own == true)
                    SureBtn(label: '✕', onSure: () => _run(() async {
                      for (final c in gcs.where((c) => c['goal'] == g['id'])) {
                        await FamStore.del(id, 'gc', '${c['id']}');
                      }
                      await FamStore.del(id, 'goals', '${g['id']}');
                    })),
                ]),
              ]),
            );
          }),
      ]),
      if (st.role != 'child')
        uCard('Yangi maqsad', children: [
          uField(gn, 'Maqsad nomi', max: 40),
          const SizedBox(height: 8),
          uField(ga, 'Maqsad summasi', num: true),
          const SizedBox(height: 10),
          uBtn("Maqsad qo'shish", () {
            final n = gn.text.trim();
            final a = parseAmount(ga.text);
            if (n.length < 2) return _msg('Maqsad nomini kiriting.');
            if (a == null || a <= 0 || a > 1e12) return _msg("Summani to'g'ri kiriting.");
            _run(() async {
              await FamStore.put(id, 'goals', nid(), {'name': n, 'target': a, 'by': st.uid, 'ts': DateTime.now().millisecondsSinceEpoch});
              gn.clear();
              ga.clear();
              _msg("Maqsad qo'shildi");
            });
          }),
        ]),
    ]);
  }

  /* 3: analysis */
  Widget _analysis(dynamic st) {
    final ms = st.members as List<Map<String, dynamic>>;
    final D = st.D as Map<String, dynamic>;
    final txs = st.txs as List<Map<String, dynamic>>;
    final mtx = _mtx(txs, mk);
    final byM = <String, double>{}, byC = <String, double>{}, pm = <String, double>{};
    var tot = 0.0;
    for (final x in mtx) {
      if (x['t'] == 'out') {
        final a = ((x['a'] ?? 0) as num).toDouble();
        byM['${x['by']}'] = (byM['${x['by']}'] ?? 0) + a;
        byC['${x['c']}'] = (byC['${x['c']}'] ?? 0) + a;
        tot += a;
      }
    }
    for (final x in _mtx(txs, prevMonthKey(mk))) {
      if (x['t'] == 'out') pm['${x['by']}'] = (pm['${x['by']}'] ?? 0) + ((x['a'] ?? 0) as num).toDouble();
    }
    final lim = ((D['limit'] ?? 0) as num).toDouble();
    final lp = lim > 0 ? math.min(100.0, tot / lim * 100) : 0.0;
    final ids = byM.keys.toList()..sort((a, b) => byM[b]!.compareTo(byM[a]!));
    final mx = ids.isEmpty ? 1.0 : byM[ids.first]!;
    final cs = byC.keys.toList()..sort((a, b) => byC[b]!.compareTo(byC[a]!));
    final kids = ms.where((m) => m['role'] == 'child' && ((m['pocket'] ?? 0) as num) > 0).toList();
    if (flim.text.isEmpty && lim > 0) flim.text = '${lim % 1 == 0 ? lim.toInt() : lim}';
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _mon(),
      uCard('Oilaviy byudjet', children: [
        if (lim > 0) ...[
          uBar(lp / 100, tot > lim ? C.out : lp >= 80 ? C.warn : C.accent),
          const SizedBox(height: 8),
          URow(title: 'Sarflandi', sub: 'Oylik limit ${mny(lim)}', amount: mny(tot), amountColor: tot > lim ? C.out : null),
          NoteBox(tot > lim ? 'Limitdan ${mny(tot - lim)} oshdi.' : '${mny(lim - tot)} qoldi.'),
        ] else
          uSmall('Oylik oilaviy limit belgilanmagan. Jami chiqim: ${mny(tot)}.'),
        if (st.own == true) ...[
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: uField(flim, 'Oylik limit', num: true)),
            const SizedBox(width: 8),
            SizedBox(
              width: 110,
              child: uBtn('Saqlash', () {
                final lv = flim.text.trim().isEmpty ? 0.0 : parseAmount(flim.text);
                if (lv == null || lv < 0 || lv > 1e12) return _msg('Limitni raqam bilan kiriting.');
                _run(() async {
                  await FamStore.patchDoc(st.id as String, {'limit': lv});
                  _msg('Limit saqlandi');
                });
              }),
            ),
          ]),
        ],
      ]),
      uCard("A'zolar bo'yicha chiqim", children: [
        if (ids.isEmpty) uSmall("Bu oyda chiqim yo'q."),
        for (final u in ids)
          Builder(builder: (_) {
            final pv = pm[u] ?? 0, df = byM[u]! - pv;
            final nm = _nm(ms, u);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                _av(ms, u, nm),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(nm, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text("${(byM[u]! / tot * 100).round()}% · o'tgan oy: ${mny(pv)}", style: const TextStyle(color: C.dim, fontSize: 12)),
                    const SizedBox(height: 4),
                    uBar(byM[u]! / mx, _col(ms, u)),
                  ]),
                ),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(mny(byM[u]!), style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text('${df > 0 ? '↑ +' : df < 0 ? '↓ −' : ''}${mny(df.abs())}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: df > 0 ? C.out : df < 0 ? C.accent : C.dim)),
                ]),
              ]),
            );
          }),
      ]),
      uCard('Kategoriyalar', children: [
        if (cs.isEmpty) uSmall("Ma'lumot yo'q."),
        for (final c in cs)
          Builder(builder: (_) {
            final cc = catOf('out', c);
            return URow(title: cc.name, sub: '${(byC[c]! / tot * 100).round()}%', amount: mny(byC[c]!));
          }),
      ]),
      if (kids.isNotEmpty)
        uCard("Bolalar cho'ntak puli", children: [
          for (final m in kids)
            Builder(builder: (_) {
              final u = byM['${m['id']}'] ?? 0, pocket = (m['pocket'] as num).toDouble();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Expanded(child: Text('${m['name']}', style: const TextStyle(fontWeight: FontWeight.w700))), Text(u > pocket ? 'Oshdi' : '${mny(pocket - u)} qoldi', style: TextStyle(fontWeight: FontWeight.w800, color: u > pocket ? C.out : C.ink))]),
                  Text('${mny(u)} / ${mny(pocket)}', style: const TextStyle(color: C.dim, fontSize: 12)),
                  const SizedBox(height: 4),
                  uBar(u / pocket, u > pocket ? C.out : C.accent),
                ]),
              );
            }),
        ]),
    ]);
  }
}

/* ====================================================================== */
/*  VAULT EHSON: verified mosque / charity / project catalog (DEMO mode)   */
/* ====================================================================== */
const Map<String, String> kEhT = {'mosque': 'Masjidlar', 'charity': 'Xayriya tashkilotlari', 'project': 'Ijtimoiy loyihalar', 'hist': 'Ehsonlar tarixi', 'trust': 'Shaffoflik'};
const Map<String, IconData> kEhI = {'mosque': Icons.mosque_rounded, 'charity': Icons.favorite_rounded, 'project': Icons.home_work_rounded};

List<Map<String, dynamic>> _ehSamples() {
  Map<String, dynamic> d(String id, String t, String n, String r, String sm, String ds, Map<String, dynamic> ex) => {'id': id, 'type': t, 'name': n, 'region': r, 'address': r, 'summary': sm, 'description': ds, 'demo': true, ...ex};
  return [
    d('demo-m1', 'mosque', 'Namuna masjid — 1', 'Namuna hudud A', "Masjid kartasi qanday ko'rinishini ko'rsatuvchi namuna.", "Haqiqiy masjid kartasida tasdiqlangan tavsif, manzil va rasmiy aloqa ma'lumotlari bo'ladi.", {'purpose': 'Namuna: masjidni ta\'mirlash va obodonlashtirish'}),
    d('demo-m2', 'mosque', 'Namuna masjid — 2', 'Namuna hudud B', 'Ikkinchi namuna kartasi (filtr va qidiruvni sinash uchun).', "Bu yozuv haqiqiy emas va hech qanday tashkilotga tegishli emas.", {'purpose': 'Namuna: jamoat ehtiyojlari'}),
    d('demo-c1', 'charity', 'Namuna xayriya tashkiloti', 'Namuna hudud A', 'Xayriya tashkiloti kartasi namunasi.', "Haqiqiy tashkilotda rasmiy nom, tekshiruv holati va hisobotlar ko'rsatiladi.", {'field': 'Namuna: ijtimoiy yordam', 'purpose': "Namuna: muhtoj oilalarni qo'llab-quvvatlash"}),
    d('demo-p1', 'project', 'Namuna loyiha — Ta\'lim', 'Namuna hudud B', "Ta'limni qo'llab-quvvatlash loyihasi namunasi.", "Haqiqiy loyihada maqsad, tasdiqlangan tashkilot va hisobotlar bo'ladi. Yig'ilgan mablag' faqat haqiqiy ma'lumot bo'lsa ko'rsatiladi.", {'field': "Ta'lim", 'purpose': "Namuna: o'quv xarajatlariga yordam", 'status': 'Namuna'}),
    d('demo-p2', 'project', 'Namuna loyiha — Tibbiy yordam', 'Namuna hudud A', 'Tibbiy yordam loyihasi namunasi.', "Bu yozuv faqat dizayn va oqimni ko'rsatish uchun.", {'field': 'Tibbiyot', 'purpose': 'Namuna: tibbiy yordam', 'status': 'Namuna'}),
  ];
}

class EhsonTab extends StatefulWidget {
  final ShellApi api;
  const EhsonTab({super.key, required this.api});
  @override
  State<EhsonTab> createState() => _EhsonTabState();
}

class _EhsonTabState extends State<EhsonTab> {
  String tab = 'mosque', q = '', rg = '';
  String? id;
  int flow = 0;
  double amt = 0;
  bool load = true;
  String err = '';
  List<Map<String, dynamic>> reg = [];
  List<String> saved = [];
  List<Map<String, dynamic>> demo = [];
  final qc = TextEditingController(), ac = TextEditingController();
  SharedPreferences? sp0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    qc.dispose();
    ac.dispose();
    super.dispose();
  }

  List _j(String k) {
    try {
      final v = sp0?.getString(k);
      if (v == null) return [];
      final d = jsonDecode(v);
      return d is List ? d : [];
    } catch (_) {
      return [];
    }
  }

  Future<void> _load() async {
    sp0 = await SharedPreferences.getInstance();
    reg = [
      for (final x in _j('vx-ehson-registry'))
        if (x is Map && x['verified'] == true && x['verifiedBy'] != null && x['verifiedAt'] != null && x['id'] != null && x['name'] != null && ['mosque', 'charity', 'project'].contains(x['type']) && x['status'] != 'archived' && x['status'] != 'closed') Map<String, dynamic>.from(x)
    ];
    saved = [for (final e in _j('vx-ehson-saved')) '$e'];
    demo = [for (final e in _j('vx-ehson-demo')) if (e is Map) Map<String, dynamic>.from(e)];
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (mounted) setState(() => load = false);
  }

  Future<void> _put(String k, Object v) async => sp0?.setString(k, jsonEncode(v));
  List<Map<String, dynamic>> get all => reg.isNotEmpty ? reg : _ehSamples();
  Map<String, dynamic>? get cur => id == null ? null : all.cast<Map<String, dynamic>?>().firstWhere((r) => '${r!['id']}' == id, orElse: () => null);

  Widget _ok(bool dm) => Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: dm ? const Color(0xFF6B5313) : C.accent.withOpacity(.5))),
        child: Text(dm ? 'NAMUNA · DEMO' : '✓ Administrator tasdiqlagan', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: dm ? const Color(0xFFF5CF6B) : C.accent)),
      );

  Widget _ph(Map<String, dynamic> x, double h) {
    final t = '${x['type']}';
    final u = '${x['photo'] ?? ''}';
    return Container(
      height: h,
      width: double.infinity,
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [HSLColor.fromAHSL(1, t == 'mosque' ? 160 : t == 'charity' ? 150 : 170, .62, .22).toColor(), const Color(0xFF050807)])),
      child: u.startsWith('https://') ? Image.network(u, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(kEhI[t], size: 54, color: C.accent)) : Icon(kEhI[t], size: 54, color: C.accent),
    );
  }

  Widget _card(Map<String, dynamic> x) {
    final sv = saved.contains('${x['id']}');
    return GestureDetector(
      onTap: () => setState(() {
        id = '${x['id']}';
        flow = 0;
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: const Color(0x0AFFFFFF), border: Border.all(color: C.line)),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _ph(x, 110),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${x['name']}${sv ? ' ♥' : ''}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
              Text('${x['region'] ?? x['address'] ?? ''}', style: const TextStyle(color: C.dim, fontSize: 12.5)),
              Text('${x['summary'] ?? ''}', style: const TextStyle(color: C.dim, fontSize: 12.5)),
              _ok(x['demo'] == true),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _dl(String t, Object? v) => (v == null || '$v'.isEmpty)
      ? const SizedBox.shrink()
      : Padding(padding: const EdgeInsets.only(bottom: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(color: C.mute, fontSize: 11.5, fontWeight: FontWeight.w700)), Text('$v', style: const TextStyle(fontSize: 13.5))]));

  Widget _detail(Map<String, dynamic> x) {
    final sv = saved.contains('${x['id']}');
    final dm = x['demo'] == true;
    final fund = (x['goal'] is num && x['raised'] is num) ? '${grp(x['raised'] as num)} / ${grp(x['goal'] as num)} so\'m' : '';
    String ver = '';
    if (!dm) {
      final a = x['verifiedAt'];
      final dt = a is num ? DateTime.fromMillisecondsSinceEpoch(a.toInt()) : DateTime.tryParse('$a');
      ver = 'Tasdiqlangan: ${dt == null ? '' : dayKey(dt)}';
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextButton(onPressed: () => setState(() {
            id = null;
            flow = 0;
          }), child: const Text('← Orqaga')),
      ClipRRect(borderRadius: BorderRadius.circular(18), child: _ph(x, 170)),
      const SizedBox(height: 12),
      Text('${x['name']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
      _ok(dm),
      const SizedBox(height: 14),
      _dl('Manzil / hudud', x['address'] ?? x['region']),
      _dl('Tavsif', x['description'] ?? x['summary']),
      _dl("Faoliyat yo'nalishi", x['field']),
      _dl('Tasdiqlangan tashkilot', x['org']),
      _dl("Mablag' yo'naltiriladigan maqsad", x['purpose']),
      _dl('Hamkorlik holati', x['partnership']),
      _dl('Tekshiruv holati', dm ? "Tasdiqlanmagan — namuna ma'lumot" : ver),
      _dl("Yig'ilgan mablag'", fund),
      _dl('Loyiha holati', x['status']),
      _dl('Rasmiy aloqa', x['contact']),
      if (x['reports'] is List)
        for (final r in (x['reports'] as List))
          if (r is Map && r['title'] != null && '${r['url']}'.startsWith('https://')) _dl('Hisobot', '${r['title']} — ${r['url']}'),
      Row(children: [
        Expanded(child: uBtn('Ehson qilish', () => setState(() {
              flow = 1;
              amt = 0;
              err = '';
              ac.clear();
            }))),
        const SizedBox(width: 8),
        Expanded(child: uBtn(sv ? 'Saqlangan ♥' : "Saqlab qo'yish", () async {
          sv ? saved.remove('${x['id']}') : saved.add('${x['id']}');
          await _put('vx-ehson-saved', saved);
          setState(() {});
        }, ghost: true)),
      ]),
    ]);
  }

  Widget _flow(Map<String, dynamic> x) {
    const amts = [10000, 50000, 100000, 500000];
    final kids = <Widget>[
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: C.warn.withOpacity(.12), borderRadius: BorderRadius.circular(12)), child: const Text("DEMO REJIM — haqiqiy pul yechilmaydi", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5))),
      TextButton(onPressed: () => setState(() => flow > 1 ? flow-- : flow = 0), child: const Text('← Orqaga')),
      Text('${x['name']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
      Text('$flow/4 · Ehson qilish mutlaqo ixtiyoriy', style: const TextStyle(color: C.dim, fontSize: 13)),
      const SizedBox(height: 10),
    ];
    if (flow == 1) {
      kids.addAll([
        const Text("Miqdorni tanlang yoki kiriting (so'm):"),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final a in amts) ChoiceChip(label: Text(grp(a)), selected: amt == a, onSelected: (_) => setState(() {
                  amt = a.toDouble();
                  ac.clear();
                }))]),
        const SizedBox(height: 8),
        uField(ac, 'Boshqa miqdor', num: true),
        if (err.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(err, style: const TextStyle(color: C.out, fontSize: 12.5))),
        const SizedBox(height: 10),
        uBtn('Davom etish', () {
          final v = ac.text.trim().isNotEmpty ? (parseAmount(ac.text) ?? 0).roundToDouble() : amt;
          if (v < 1000) return setState(() => err = "Kamida 1 000 so'm miqdorini tanlang yoki kiriting.");
          setState(() {
            amt = v;
            err = '';
            flow = 2;
          });
        }),
      ]);
    } else if (flow == 2) {
      kids.addAll([const NoteBox("To'lov usullari hozircha faol emas. Ular faqat rasmiy hamkorlik, huquqiy talablar va vakolatli to'lov provayderi integratsiyasi tasdiqlangach ulanadi.\n\nKarta raqami, CVV yoki PIN so'ralmaydi."), const SizedBox(height: 10), uBtn('Davom etish', () => setState(() => flow = 3))]);
    } else if (flow == 3) {
      kids.addAll([URow(title: "Yo'nalish", amount: '${x['name']}'), URow(title: 'Miqdor', amount: "${grp(amt)} so'm"), const URow(title: 'Rejim', amount: "Demo — pul yechilmaydi"), const SizedBox(height: 6), uBtn('Tekshirdim, davom etish', () => setState(() => flow = 4))]);
    } else {
      kids.addAll([
        const NoteBox("Yakuniy bosqich. Demo yozuv faqat sizning qurilmangizda, haqiqiy ehsonlardan alohida saqlanadi. Hech qanday chek yoki tranzaksiya yaratilmaydi."),
        const SizedBox(height: 10),
        uBtn('Demo yozuvni saqlash', () async {
          demo.add({'name': x['name'], 'amount': amt, 'at': DateTime.now().millisecondsSinceEpoch, 'demo': true});
          await _put('vx-ehson-demo', demo);
          if (mounted) {
            toast(context, "Demo yozuv saqlandi — pul yechilmadi");
            setState(() {
              flow = 0;
              id = null;
              tab = 'hist';
            });
          }
        }),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: kids);
  }

  Widget _list() {
    final items = all.where((x) => x['type'] == tab).toList();
    final rgs = <String>[];
    for (final x in items) {
      final r = '${x['region'] ?? ''}';
      if (r.isNotEmpty && !rgs.contains(r)) rgs.add(r);
    }
    final ql = q.trim().toLowerCase();
    final L = items.where((x) => (rg.isEmpty || x['region'] == rg) && (ql.isEmpty || '${x['name']} ${x['address'] ?? ''} ${x['summary'] ?? ''}'.toLowerCase().contains(ql))).toList();
    final bar = Row(children: [
      Expanded(child: uField(qc, 'Qidirish…', onChanged: (v) => setState(() => q = v))),
      const SizedBox(width: 8),
      DropdownButton<String>(value: rgs.contains(rg) ? rg : '', dropdownColor: C.bg2, items: [const DropdownMenuItem(value: '', child: Text('Barcha hududlar')), for (final r in rgs) DropdownMenuItem(value: r, child: Text(r))], onChanged: (v) => setState(() => rg = v ?? '')),
    ]);
    if (items.isEmpty) return Column(children: [bar, const SizedBox(height: 14), NoteBox("${kEhT[tab]} tez orada. Bu bo'limda hozircha administrator tasdiqlagan yozuvlar yo'q.")]);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (reg.isEmpty) const Padding(padding: EdgeInsets.only(bottom: 10), child: NoteBox("NAMUNA MA'LUMOTLAR — dizaynni ko'rsatish uchun, haqiqiy emas")),
      bar,
      const SizedBox(height: 12),
      if (L.isEmpty) const NoteBox("Hech narsa topilmadi. Qidiruv yoki hududni o'zgartirib ko'ring.") else ...L.map(_card),
    ]);
  }

  Widget _hist() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const NoteBox("Haqiqiy ehsonlar: hozircha yo'q — to'lovlar yoqilmagan."),
        const SizedBox(height: 14),
        const Text('Demo yozuvlar · DEMO', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        const SizedBox(height: 8),
        if (demo.isEmpty) const NoteBox("Demo yozuvlar yo'q. Demo ehson qilsangiz, shu yerda alohida ko'rinadi.")
        else
          for (final r in demo.reversed)
            URow(title: '${r['name']}', sub: "Demo — pul yechilmagan · ${dayKey(DateTime.fromMillisecondsSinceEpoch(((r['at'] ?? 0) as num).toInt()))}", amount: "${grp((r['amount'] ?? 0) as num)} so'm"),
      ]);

  @override
  Widget build(BuildContext context) {
    final x = cur;
    Widget body;
    if (load) {
      body = const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: C.accent)));
    } else if (x != null) {
      body = flow > 0 ? _flow(x) : _detail(x);
    } else if (tab == 'hist') {
      body = _hist();
    } else if (tab == 'trust') {
      body = const NoteBox("Ishonch — birinchi o'rinda\n\n• Faqat administrator shaxsini, hisob egasini va hamkorlik hujjatlarini tekshirgan yozuvlar ko'rsatiladi.\n• Tekshirilmagan tashkilotlar katalogga chiqmaydi.\n• Har bir yo'nalishda mablag' maqsadi va hisobotlari ko'rsatiladi.\n• Hozir barcha to'lovlar DEMO rejimida — haqiqiy pul qabul qilinmaydi.");
    } else {
      body = _list();
    }
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
      Center(child: Column(children: [
        Container(width: 54, height: 54, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: C.accent.withOpacity(.5))), child: const Icon(Icons.favorite_rounded, color: C.accent)),
        const SizedBox(height: 8),
        const Text('VAULT EHSON', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const Text('Yaxshilik bir qadam narida', style: TextStyle(color: C.accent, fontSize: 13)),
        const SizedBox(height: 6),
        const Text("Tasdiqlangan masjidlar, xayriya tashkilotlari va ijtimoiy loyihalar bir joyda. Ehson qilish — faqat sizning ixtiyoringizda.", textAlign: TextAlign.center, style: TextStyle(color: C.dim, fontSize: 12.5)),
      ])),
      const SizedBox(height: 12),
      if (x == null) SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [for (final k in kEhT.keys) Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(kEhT[k]!), selected: tab == k, onSelected: (_) => setState(() {
                tab = k;
                q = '';
                rg = '';
                qc.clear();
                id = null;
                flow = 0;
              })))])),
      const SizedBox(height: 12),
      body,
      const Center(child: Padding(padding: EdgeInsets.only(top: 14), child: Text('VAULT EHSON · FROM EIGHTEEN', style: TextStyle(color: C.mute, fontSize: 11, letterSpacing: 1.2)))),
    ]);
  }
}

/* ====================================================================== */
/*  ELITE (logic + chart painters)                                         */
/* ====================================================================== */
const Color kGold = Color(0xFFD4AF37), kGold2 = Color(0xFFF5D97A), kGoldD = Color(0xFF8A6D1D), kEBad = Color(0xFFE0613C), kERed = Color(0xFFD6303A);

String sgn(num n) => '${n < 0 ? '−' : ''}${mny(n.abs())}';
String sdn(num n) => '${n >= 0 ? '+' : '−'}${mny(n.abs())}';
String kM3(int m) => monthName(m).length > 3 ? monthName(m).substring(0, 3) : monthName(m);
String eDL(String d) => '${int.parse(d.substring(8, 10))}-${monthName(int.parse(d.substring(5, 7))).toLowerCase()}';
String nextMonthKey(String mk) {
  final p = mk.split('-');
  return monthKeyOf(DateTime(int.parse(p[0]), int.parse(p[1]) + 1, 1));
}

double nd(dynamic v) => v is num ? v.toDouble() : (double.tryParse('$v') ?? 0);
List<Map<String, dynamic>> eL(Map<String, dynamic> m, String k) {
  final v = m[k];
  if (v is List) return v.cast<Map<String, dynamic>>();
  final n = <Map<String, dynamic>>[];
  m[k] = n;
  return n;
}

Map<String, dynamic> eM(Map<String, dynamic> m, String k) {
  final v = m[k];
  if (v is Map<String, dynamic>) return v;
  final n = <String, dynamic>{};
  m[k] = n;
  return n;
}

String eShort(double v) {
  final a = v.abs(), s = v < 0 ? '−' : '';
  String f(double x) => (x % 1 == 0 ? x.toStringAsFixed(0) : x.toStringAsFixed(1));
  if (a >= 1e9) return '$s${f(a / 1e9)}B';
  if (a >= 1e6) return '$s${f(a / 1e6)}M';
  if (a >= 1e3) return '$s${f(a / 1e3)}k';
  return '$s${f(a)}';
}

double eAxisMax(double v) {
  if (v <= 0) return 1;
  final e = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
  final n = v / e;
  return (n <= 1 ? 1 : n <= 2 ? 2 : n <= 5 ? 5 : 10) * e;
}

Map<String, dynamic> eInit() {
  final p = app.profile!;
  final E = p.mp('el');
  eL(E, 'cos');
  E['act'] ??= 'all';
  for (final c in eL(E, 'cos')) {
    for (final k in ['inv', 'staff', 'stock', 'tl']) {
      eL(c, k);
    }
    eM(c, 'plan');
    c['cash'] = nd(c['cash']);
    c['fixed'] = nd(c['fixed']);
    c['tax'] = nd(c['tax']);
  }
  final cos = eL(E, 'cos');
  if (E['act'] != 'all' && !cos.any((c) => c['id'] == E['act'])) E['act'] = 'all';
  return E;
}

List<Map<String, dynamic>> eVis() {
  final E = eInit();
  final cos = eL(E, 'cos');
  return E['act'] == 'all' ? cos : cos.where((c) => c['id'] == E['act']).toList();
}

Set<String> eVset() => {for (final c in eVis()) '${c['id']}'};
Map<String, dynamic>? eCo(String id) {
  for (final c in eL(eInit(), 'cos')) {
    if (c['id'] == id) return c;
  }
  return null;
}

String eTag(Map<String, dynamic> c) => eL(eInit(), 'cos').length > 1 ? ' · ${c['name']}' : '';

List<Tx> eTx(String mk) {
  final s = eVset();
  return app.listOf(mk).where((x) => x.ex['e'] != null && s.contains('${x.ex['e']}')).toList();
}

class ESum {
  double i = 0, o = 0, cg = 0;
  final Map<String, double> bi = {}, bo = {};
}

ESum eSum(Iterable<Tx> l) {
  final s = ESum();
  for (final x in l) {
    if (x.t == 'in') {
      s.i += x.a;
      s.cg += nd(x.ex['cg']);
      s.bi[x.c] = (s.bi[x.c] ?? 0) + x.a;
    } else {
      s.o += x.a;
      s.bo[x.c] = (s.bo[x.c] ?? 0) + x.a;
    }
  }
  return s;
}

ESum eMon(String mk) => eSum(eTx(mk));
double eStockCost(ESum s) => s.cg > 0 ? s.cg : (s.bo['b_stock'] ?? 0);
double eProf(ESum s) => s.i - (s.o - (s.bo['b_stock'] ?? 0)) - eStockCost(s);

double eBal(List<Map<String, dynamic>> cos) {
  final set = {for (final c in cos) '${c['id']}'};
  var b = 0.0;
  for (final c in cos) {
    b += nd(c['cash']);
  }
  for (final x in app.txs) {
    if (x.ex['e'] != null && set.contains('${x.ex['e']}')) b += x.t == 'in' ? x.a : -x.a;
  }
  return r2(b);
}

double eTaxSum(String mk) {
  var t = 0.0;
  for (final c in eVis()) {
    var i = 0.0;
    for (final x in app.listOf(mk)) {
      if (x.ex['e'] == c['id'] && x.t == 'in') i += x.a;
    }
    t += i * nd(c['tax']) / 100;
  }
  return fixAmt(t);
}

int eDays(String ref) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day).difference(parseDay(ref)).inDays;
}

/* ---- aging ---- */
const List<(String, Color)> kAgeB = [("Muddati o'tmagan", Color(0xFF8FC98A)), ('1–7 kun', Color(0xFFD4AF37)), ('8–30 kun', Color(0xFFE08A3C)), ('31–60 kun', Color(0xFFE0613C)), ("60 kundan ko'p", Color(0xFFD6303A))];

class EAge {
  final List<double> t = List.filled(5, 0);
  final List<int> n = List.filled(5, 0);
  final List<({Map<String, dynamic> v, Map<String, dynamic> c, double d, int days, int i})> rows = [];
  double tot = 0, o7 = 0;
}

EAge eAge() {
  final a = EAge();
  for (final c in eVis()) {
    for (final v in eL(c, 'inv')) {
      final d = fixAmt(nd(v['total']) - nd(v['paid']));
      if (!(d > .001)) continue;
      final days = eDays('${v['due'] ?? ''}'.isNotEmpty ? '${v['due']}' : '${v['date']}');
      final i = days <= 0 ? 0 : days <= 7 ? 1 : days <= 30 ? 2 : days <= 60 ? 3 : 4;
      a.t[i] += d;
      a.n[i]++;
      a.tot += d;
      if (i >= 2) a.o7 += d;
      a.rows.add((v: v, c: c, d: d, days: days, i: i));
    }
  }
  a.rows.sort((x, y) => y.days.compareTo(x.days));
  return a;
}

/* ---- forecast ---- */
class EFore {
  bool has = false;
  double bal = 0, net = 0, ai = 0, ao = 0, pay = 0, fx = 0;
  int n = 0;
  final List<(String, double)> pts = [];
  String? sh;
}

EFore eFore([double adj = 0]) {
  final cos = eVis();
  final mk = monthKeyOf(DateTime.now());
  final k1 = prevMonthKey(mk), k2 = prevMonthKey(k1), k3 = prevMonthKey(k2);
  var si = 0.0, so = 0.0, sp_ = 0.0, n = 0, fx = 0.0, pay = 0.0;
  final bal = eBal(cos);
  for (final k in [k1, k2, k3]) {
    final s = eMon(k);
    if (s.i > 0 || s.o > 0) {
      n++;
      si += s.i;
      so += s.o - (s.bo['b_pay'] ?? 0);
      sp_ += s.bo['b_pay'] ?? 0;
    }
  }
  for (final c in cos) {
    fx += nd(c['fixed']);
    for (final x in eL(c, 'staff')) {
      pay += nd(x['sal']);
    }
  }
  if (pay == 0 && n > 0) pay = sp_ / n;
  final ai = n > 0 ? si / n : 0.0, ao = n > 0 ? so / n : 0.0;
  final net = ai - ao - pay - fx + adj;
  final has = n > 0 || pay > 0 || fx > 0;
  final y = int.parse(mk.substring(0, 4)), mo = int.parse(mk.substring(5, 7));
  final dim = daysIn(y, mo), td = DateTime.now().day;
  final f = (dim - td) / dim;
  final r = EFore()
    ..has = has
    ..bal = bal
    ..net = net
    ..ai = ai
    ..ao = ao
    ..pay = pay
    ..fx = fx
    ..n = n;
  r.pts.add(('Hozir', bal));
  var cb = bal;
  var m = mk;
  final segs = <({double s, double e, int len, String mk, int st})>[];
  var e = cb + net * f;
  segs.add((s: cb, e: e, len: dim - td, mk: mk, st: td));
  r.pts.add(('${kM3(mo)} oxiri', fixAmt(e)));
  cb = e;
  for (var i = 0; i < 2; i++) {
    m = nextMonthKey(m);
    final mm = int.parse(m.substring(5, 7));
    e = cb + net;
    segs.add((s: cb, e: e, len: daysIn(int.parse(m.substring(0, 4)), mm), mk: m, st: 1));
    r.pts.add(('${kM3(mm)} oxiri', fixAmt(e)));
    cb = e;
  }
  if (has) {
    if (bal < 0) {
      r.sh = 'Kassa hozirdayoq manfiy';
    } else {
      for (final q in segs) {
        if (q.s >= 0 && q.e < 0) {
          final fr = q.s / (q.s - q.e);
          final dm = daysIn(int.parse(q.mk.substring(0, 4)), int.parse(q.mk.substring(5, 7)));
          final dy = math.min(dm, math.max(1, (q.st + fr * q.len).round()));
          r.sh = 'Pul tanqisligi taxminan $dy-${monthName(int.parse(q.mk.substring(5, 7))).toLowerCase()} atrofida boshlanadi';
          break;
        }
      }
    }
  }
  return r;
}

/* ---- break-even ---- */
class EBE {
  bool has = false;
  double fixed = 0, ratio = 0, cm = 0, rev = 0;
  double? be;
}

EBE eBE() {
  final cos = eVis();
  final mk = monthKeyOf(DateTime.now());
  final k1 = prevMonthKey(mk);
  var rev = 0.0, vc = 0.0, rent = 0.0, pay = 0.0, n = 0, staffP = 0.0, fx = 0.0;
  for (final k in [mk, k1, prevMonthKey(k1)]) {
    final s = eMon(k);
    if (s.i > 0) {
      final st = s.bo['b_stock'] ?? 0;
      rev += s.i;
      vc += s.o - (s.bo['b_rent'] ?? 0) - (s.bo['b_pay'] ?? 0) - st + eStockCost(s);
      rent += s.bo['b_rent'] ?? 0;
      pay += s.bo['b_pay'] ?? 0;
      n++;
    }
  }
  for (final c in cos) {
    fx += nd(c['fixed']);
    for (final x in eL(c, 'staff')) {
      staffP += nd(x['sal']);
    }
  }
  final fixed = (n > 0 ? rent / n : 0) + math.max(staffP, n > 0 ? pay / n : 0) + fx;
  final ratio = rev > 0 ? vc / rev : 0.0, cm = 1 - ratio;
  final r = EBE()
    ..has = rev > 0
    ..fixed = fixed.toDouble()
    ..ratio = ratio
    ..cm = cm
    ..rev = eMon(mk).i;
  r.be = (rev > 0 && cm > 0) ? fixed / cm : null;
  return r;
}

({String s, String l}) eStaffSt(Map<String, dynamic> x) {
  final now = DateTime.now();
  final cm = monthKeyOf(now), dd = now.day;
  final de = math.min(nd(x['day']).toInt(), daysIn(now.year, now.month));
  final paid = x['paid'];
  if (paid is Map && paid[cm] != null) return (s: 'paid', l: "To'langan");
  if (de < dd) return (s: 'late', l: 'Kechikdi (${dd - de} kun)');
  if (de == dd) return (s: 'soon', l: 'Bugun');
  return (s: de - dd <= 3 ? 'soon' : 'open', l: '${de - dd} kundan keyin');
}

/* ---- base / what-if ---- */
class EBase {
  int n = 0, ns = 0;
  double rev = 0, ratio = 0, rent = 0, pay = 0, fx = 0, avgSal = 0;
}

EBase eBase() {
  final cos = eVis();
  final mk = monthKeyOf(DateTime.now());
  final k1 = prevMonthKey(mk), k2 = prevMonthKey(k1), k3 = prevMonthKey(k2);
  var n = 0, ns = 0;
  var rev = 0.0, vc = 0.0, rent = 0.0, pay = 0.0, staffP = 0.0, fx = 0.0;
  void run(List<String> ks) {
    for (final k in ks) {
      final s = eMon(k);
      if (s.i > 0) {
        final st = s.bo['b_stock'] ?? 0;
        rev += s.i;
        vc += s.o - (s.bo['b_rent'] ?? 0) - (s.bo['b_pay'] ?? 0) - st + eStockCost(s);
        rent += s.bo['b_rent'] ?? 0;
        pay += s.bo['b_pay'] ?? 0;
        n++;
      }
    }
  }

  run([k1, k2, k3]);
  if (n == 0) run([mk]);
  for (final c in cos) {
    fx += nd(c['fixed']);
    for (final x in eL(c, 'staff')) {
      staffP += nd(x['sal']);
      ns++;
    }
  }
  return EBase()
    ..n = n
    ..rev = n > 0 ? rev / n : 0
    ..ratio = rev > 0 ? vc / rev : 0
    ..rent = n > 0 ? rent / n : 0
    ..pay = math.max(staffP, n > 0 ? pay / n : 0)
    ..fx = fx
    ..ns = ns
    ..avgSal = ns > 0 ? staffP / ns : 0;
}

/* ---- calendar ---- */
class ECal {
  final List<({String d, double v, List<({String d, double a, String n, String k})> ev})> days = [];
  ({String d, double v, List<({String d, double a, String n, String k})> ev})? first;
  late ({double v, String d}) min;
  double bal = 0, need = 0, out = 0, odTot = 0, dly = 0;
  final List<({String c, double d})> od = [], res = [];
  bool cover = false, hasData = false;
}

ECal eCal(bool expected) {
  const H = 60;
  final t0 = todayStr(), end = dAdd(t0, H), cm = monthKeyOf(DateTime.now());
  final cos = eVis();
  final b = eBase();
  final bal = eBal(cos);
  final ev = <({String d, double a, String n, String k})>[];
  void add(String d, double a, String n, String k) {
    if (d.compareTo(t0) >= 0 && d.compareTo(end) <= 0) ev.add((d: d, a: a, n: n, k: k));
  }

  String dim(String m, int day) => '$m-${two(math.min(day, daysIn(int.parse(m.substring(0, 4)), int.parse(m.substring(5, 7)))))}';
  for (final c in cos) {
    for (final x in eL(c, 'staff')) {
      var m = cm;
      for (var i = 0; i < 4; i++) {
        final dd = dim(m, nd(x['day']).toInt());
        final paid = x['paid'];
        if (!(paid is Map && paid[m] != null)) {
          if (dd.compareTo(t0) < 0) {
            if (m == cm) add(t0, -nd(x['sal']), 'Ish haqi: ${x['name']} (kechikkan)', 'pay');
          } else {
            add(dd, -nd(x['sal']), 'Ish haqi: ${x['name']}', 'pay');
          }
        }
        m = nextMonthKey(m);
      }
    }
    for (final x in eL(c, 'tl')) {
      if (x['kind'] == 'm') {
        var m = cm;
        for (var i = 0; i < 4; i++) {
          add(dim(m, nd(x['day']).toInt()), nd(x['amt']) > 0 ? -nd(x['amt']) : 0, '${x['name']}', 'tax');
          m = nextMonthKey(m);
        }
      } else if ('${x['date'] ?? ''}'.isNotEmpty) {
        add('${x['date']}', nd(x['amt']) > 0 ? -nd(x['amt']) : 0, '${x['name']}', 'tax');
      }
    }
    if (nd(c['fixed']) > 0) {
      var m2 = cm;
      for (var i = 0; i < 4; i++) {
        add('$m2-01', -nd(c['fixed']), 'Doimiy xarajat${eTag(c)}', 'fix');
        m2 = nextMonthKey(m2);
      }
    }
    if (!expected) {
      for (final v in eL(c, 'inv')) {
        final d = fixAmt(nd(v['total']) - nd(v['paid']));
        if (d > .001) add('${v['due'] ?? ''}'.isNotEmpty ? '${v['due']}' : '${v['date']}', d, "To'lov kutilmoqda: ${v['client']}", 'in');
      }
    }
  }
  if (b.rent > 0) {
    var m3 = cm;
    for (var i = 0; i < 4; i++) {
      add('$m3-01', -b.rent, "Ijara (o'rtacha)", 'fix');
      m3 = nextMonthKey(m3);
    }
  }
  final r = ECal();
  r.dly = expected && b.n > 0 ? b.rev * (1 - b.ratio) / 30 : 0;
  var run = bal;
  r.min = (v: bal, d: t0);
  for (var i = 0; i <= H; i++) {
    final d = dAdd(t0, i);
    final es = ev.where((x) => x.d == d).toList();
    for (final x in es) {
      run += x.a;
      if (x.a < 0) r.out -= x.a;
    }
    if (i > 0) run += r.dly;
    run = fixAmt(run);
    final day = (d: d, v: run, ev: es);
    r.days.add(day);
    if (run < r.min.v) r.min = (v: run, d: d);
    if (run < 0 && r.first == null) r.first = day;
  }
  r.bal = bal;
  r.need = r.min.v < 0 ? -r.min.v : 0;
  for (final c in cos) {
    for (final v in eL(c, 'inv')) {
      final d = fixAmt(nd(v['total']) - nd(v['paid']));
      if (d > .001 && eDays('${v['due'] ?? ''}'.isNotEmpty ? '${v['due']}' : '${v['date']}') > 0) {
        r.od.add((c: '${v['client']}', d: d));
        r.odTot += d;
      }
    }
  }
  r.od.sort((a, b2) => b2.d.compareTo(a.d));
  var acc = 0.0;
  for (var i = 0; i < r.od.length && acc < r.need; i++) {
    r.res.add(r.od[i]);
    acc += r.od[i].d;
  }
  r.cover = acc >= r.need;
  r.hasData = b.n > 0 || ev.isNotEmpty || bal != 0;
  return r;
}

/* ---- health ---- */
(String, Color) eHL(num s) => s >= 80 ? ("A'lo", const Color(0xFF6FD3A0)) : s >= 60 ? ('Yaxshi', kGold) : s >= 40 ? ('Diqqat talab', const Color(0xFFE0A526)) : ('Xavfli', kEBad);

class EComp {
  final String l, t, adv;
  final int w, s;
  EComp(this.l, this.w, this.s, this.t, this.adv);
}

class EHealth {
  bool has = false;
  int score = 0;
  String lab = '', msg = '';
  Color col = kGold;
  List<EComp> comps = [];
  EComp? weak;
}

EHealth eHealth() {
  final cos = eVis();
  final f = eFore(), ag = eAge();
  final mk = monthKeyOf(DateTime.now());
  final s = eMon(mk), ps = eMon(prevMonthKey(mk));
  final ref = s.i > 0 ? s : ps;
  final comps = <EComp>[];
  final dd = DateTime.now().day, dim = daysIn(DateTime.now().year, DateTime.now().month);
  int cl(double v) => math.max(0, math.min(100, v.round()));
  if (f.has) {
    int sc;
    String tx;
    if (f.bal < 0) {
      sc = 0;
      tx = 'Kassa manfiy';
    } else if (f.sh != null) {
      sc = 25;
      tx = f.sh!;
    } else if (f.net >= 0) {
      sc = 100;
      tx = "Kassa o'sib bormoqda";
    } else {
      final mo = f.bal / -f.net;
      sc = cl(40 + mo / 6 * 60);
      tx = 'Kassa taxminan ${(mo * 10).round() / 10} oyga yetadi';
    }
    comps.add(EComp('Pul oqimi', 25, sc, tx, "Tushumni oshiring yoki xarajatni kamaytiring. «Kalendar» da tanqislik kunini ko'ring."));
  }
  if (ref.i > 0) {
    final mg = eProf(ref) / ref.i * 100;
    comps.add(EComp('Foyda', 25, cl(mg / 20 * 100), 'Foyda marjasi ${mg.round()}%', "Narx va tannarxni qayta ko'ring. «Agar...?» bo'limida sinab ko'ring."));
  }
  var hasInv = false;
  for (final c in cos) {
    if (eL(c, 'inv').isNotEmpty) hasInv = true;
  }
  if (hasInv) {
    final o7 = ag.t[2] + ag.t[3] + ag.t[4];
    final sc2 = ag.tot > 0 ? cl(100 - 70 * (o7 / ag.tot) - 30 * (ag.t[4] / ag.tot)) : 100;
    comps.add(EComp('Qarzdorlik', 20, sc2, ag.tot > 0 ? "7 kundan oshgan qarz: ${mny(o7)}" : "Qarz yo'q", "Kechikkan mijozlarga eslatma yuboring, yangi sotuvni oldindan to'lovga o'tkazing."));
  }
  var pr = 0.0;
  for (final c in cos) {
    pr += nd(eM(eM(c, 'plan'), mk)['rev']);
  }
  if (pr > 0 && dd >= 3) {
    final ex = pr * dd / dim;
    comps.add(EComp('Reja bajarilishi', 15, cl(s.i / ex * 100), "Tushum rejasining ${(s.i / pr * 100).round()}% i bajarilgan", "Oy oxirigacha tushumni tezlashtiring yoki rejani real qiling."));
  }
  var cnt = 0, low = 0;
  for (final c in cos) {
    for (final p in eL(c, 'stock')) {
      cnt++;
      if (nd(p['min']) > 0 && nd(p['qty']) <= nd(p['min'])) low++;
    }
  }
  if (cnt > 0) comps.add(EComp('Ombor', 15, cl(100 - 100 * low / cnt), low > 0 ? '$low ta mahsulot tugayapti' : 'Qoldiq yetarli', "Tugayotgan mahsulotlarni «Xarid» bilan to'ldiring."));
  final h = EHealth();
  if (comps.isEmpty) return h;
  var tw = 0, ts = 0;
  var weak = comps.first;
  for (final c in comps) {
    tw += c.w;
    ts += c.w * c.s;
    if (c.s < weak.s) weak = c;
  }
  final score = (ts / tw).round();
  final hl = eHL(score);
  h
    ..has = true
    ..score = score
    ..lab = hl.$1
    ..col = hl.$2
    ..comps = comps
    ..weak = weak
    ..msg = weak.s < 80 ? 'Eng zaif joyi: ${weak.l} (${weak.s} ball). ${weak.adv}' : "Hamma ko'rsatkichlar yaxshi. Shu tempni saqlang.";
  return h;
}

/* ---- alerts ---- */
List<({bool r, String t})> eAlerts() {
  final a = <({bool r, String t})>[];
  final cos = eVis();
  final fc = eFore(), ag = eAge();
  final cm = monthKeyOf(DateTime.now());
  final low = <String>[], due = <String>[], tt = <String>[];
  if (fc.has) a.add(fc.sh != null ? (r: true, t: 'Pul oqimi: ${fc.sh}.') : (r: false, t: 'Pul oqimi: keyingi 3 oyda tanqislik kutilmaydi.'));
  final kc = eCal(true);
  if (kc.first != null && parseDay(kc.first!.d).difference(parseDay(todayStr())).inDays <= 30) a.add((r: true, t: 'Kalendar: ${eDL(kc.first!.d)} kuni kassada pul yetmaydi.'));
  if (ag.t[4] > 0) a.add((r: true, t: "60 kundan oshgan qarz: ${mny(ag.t[4])} (${ag.n[4]} ta hisob-faktura)."));
  if (ag.t[3] > 0) a.add((r: true, t: '31–60 kun kechikkan qarz: ${mny(ag.t[3])}.'));
  if (ag.t[2] > 0) a.add((r: false, t: '8–30 kun kechikkan qarz: ${mny(ag.t[2])}.'));
  for (final c in cos) {
    for (final x in eL(c, 'staff')) {
      final s = eStaffSt(x);
      if (s.s == 'late' || s.s == 'soon') due.add('${x['name']} (${s.l.toLowerCase()})');
    }
    for (final p in eL(c, 'stock')) {
      if (nd(p['min']) > 0 && nd(p['qty']) <= nd(p['min'])) low.add('${p['name']}');
    }
    for (final x in eL(c, 'tl')) {
      final d = x['kind'] == 'm' ? daysTo(nd(x['day']).toInt()) : dueIn('${x['date']}');
      if (d <= 3) tt.add('${x['name']}${d < 0 ? " (muddati o'tgan)" : d > 0 ? ' ($d kun)' : ' (bugun)'}');
    }
  }
  if (due.isNotEmpty) a.add((r: true, t: 'Ish haqi: ${due.take(3).join(', ')}.'));
  if (tt.isNotEmpty) a.add((r: true, t: "Soliq va to'lov muddati: ${tt.take(3).join(', ')}."));
  if (low.isNotEmpty) a.add((r: false, t: 'Ombor: ${low.take(4).join(', ')} tugayapti.'));
  var pr = 0.0;
  for (final c in cos) {
    pr += nd(eM(eM(c, 'plan'), cm)['rev']);
  }
  final cf = eMon(cm).i, dd = DateTime.now().day;
  if (pr > 0 && dd >= 15 && cf < pr * dd / daysIn(DateTime.now().year, DateTime.now().month) * .7) a.add((r: false, t: "Reja: tushum rejasining ${(cf / pr * 100).round()}% i bajarilgan, orqada qolyapsiz."));
  return a;
}

void eRemind(BuildContext context) {
  final p = app.profile;
  if (p == null || !p.isElite) return;
  final a = eAlerts().where((x) => x.r).toList();
  if (a.isNotEmpty) toast(context, 'Elite: ${a.take(2).map((x) => x.t).join(' ')}');
}

String eRepText(String mk) {
  final E = eInit();
  final cos = eVis();
  final s = eMon(mk);
  final pf = eProf(s), cg = eStockCost(s), opx = s.o - (s.bo['b_stock'] ?? 0), tax = eTaxSum(mk);
  final ag = eAge(), f = eFore(), b = eBE(), bal = eBal(cos);
  final cm = monthKeyOf(DateTime.now());
  final nm = E['act'] == 'all' ? (cos.length > 1 ? "Umumiy ko'rinish (${cos.length} ta kompaniya)" : '${cos.first['name']}') : '${cos.first['name']}';
  final o = StringBuffer('VAULT ELITE · Rahbar hisoboti\n$nm · ${mlab(mk)}\n\n');
  o.writeln("ASOSIY KO'RSATKICHLAR");
  o.writeln('Tushum: ${mny(s.i)}\nXarajat (tovar bilan): ${mny(s.o)}\nFoyda: ${sgn(pf)}\nMarja: ${s.i > 0 ? '${(pf / s.i * 100).round()}%' : '—'}');
  o.writeln('Pul oqimi: ${sgn(s.i - s.o)}\nKassa qoldig\'i: ${sgn(bal)}\nQarzdorlik: ${mny(ag.tot)}\n7 kundan oshgan qarz: ${mny(ag.o7)}\n60 kundan oshgan qarz: ${mny(ag.t[4])}');
  final q = eHealth();
  o.writeln("Biznes sog'lik balli: ${q.has ? '${q.score} / 100 (${q.lab})' : '—'}\n");
  o.writeln('FOYDA VA ZARAR\nTushum: ${mny(s.i)}\nTovar tannarxi: −${mny(cg)}\nOperatsion xarajatlar: −${mny(opx)}\nFoyda: ${sgn(pf)}');
  if (tax > 0) o.writeln('Taxminiy soliq: −${mny(tax)}\nSoliqdan keyingi foyda: ${sgn(pf - tax)}');
  final cr = s.bo.keys.toList()..sort((a, c) => s.bo[c]!.compareTo(s.bo[a]!));
  if (cr.isNotEmpty) {
    o.writeln('\nXARAJAT TUZILMASI');
    for (final k in cr) {
      o.writeln('${catOf('out', k).name}: ${mny(s.bo[k]!)} · ${(s.bo[k]! / s.o * 100).round()}%');
    }
  }
  o.writeln('\nQARZDORLIK YOSHI');
  for (var i = 0; i < 5; i++) {
    o.writeln('${kAgeB[i].$1}: ${mny(ag.t[i])} (${ag.n[i]} ta)');
  }
  var pr = 0.0, pp = 0.0;
  for (final c in cos) {
    final p = eM(eM(c, 'plan'), mk);
    pr += nd(p['rev']);
    pp += nd(p['profit']);
  }
  if (pr > 0 || pp > 0) {
    o.writeln('\nREJA VA FAKT');
    if (pr > 0) o.writeln('Tushum: reja ${mny(pr)} / fakt ${mny(s.i)} (${(s.i / pr * 100).round()}%)');
    if (pp > 0) o.writeln('Foyda: reja ${mny(pp)} / fakt ${sgn(pf)} (${(pf / pp * 100).round()}%)');
  }
  if (f.has) {
    o.writeln('\nPUL OQIMI PROGNOZI');
    for (final p in f.pts) {
      o.writeln('${p.$1}: ${sgn(p.$2)}');
    }
    o.writeln('Xulosa: ${f.sh ?? '3 oyda tanqislik kutilmaydi'}');
  }
  if (b.has && b.be != null) o.writeln("\nZARARSIZLIK NUQTASI\nOyiga: ${mny(b.be!)}\nDoimiy xarajat: ${mny(b.fixed)}\nHissa marjasi: ${(b.cm * 100).round()}%\nJoriy oy tushumi: ${mny(b.rev)}");
  var n = 0, tot = 0.0, pd = 0.0, sv = 0.0;
  for (final c in cos) {
    for (final x in eL(c, 'staff')) {
      n++;
      tot += nd(x['sal']);
      final pa = x['paid'];
      if (pa is Map && pa[cm] != null) pd += nd(x['sal']);
    }
    for (final p in eL(c, 'stock')) {
      sv += nd(p['qty']) * nd(p['cost']);
    }
  }
  if (n > 0) o.writeln('\nXODIMLAR\nSoni: $n\nOylik ish haqi fondi: ${mny(tot)}\n${mlab(cm)} da to\'langan: ${mny(pd)}');
  if (sv > 0) o.writeln('\nOMBOR\nQiymati (tannarx): ${mny(sv)}');
  o.writeln('\nSana: ${todayStr()}. Taxminiy ko\'rsatkichlar rasmiy buxgalteriya hisobi o\'rnini bosmaydi.');
  return o.toString();
}

/* ============================ chart painters ============================ */
void _txt(Canvas c, String s, Offset o, {TextAlign a = TextAlign.center, Color col = C.dim, double sz = 10, FontWeight w = FontWeight.w500}) {
  final tp = TextPainter(text: TextSpan(text: s, style: TextStyle(color: col, fontSize: sz, fontWeight: w)), textDirection: TextDirection.ltr)..layout();
  var dx = o.dx;
  if (a == TextAlign.center) dx -= tp.width / 2;
  if (a == TextAlign.right || a == TextAlign.end) dx -= tp.width;
  tp.paint(c, Offset(dx, o.dy - tp.height / 2));
}

class _Frame {
  final Size size;
  final double lo, hi;
  final double ml = 44, mr = 12, mt = 18, mb = 26;
  _Frame(this.size, this.lo, this.hi);
  double get pw => size.width - ml - mr;
  double get ph => size.height - mt - mb;
  double y(double v) => mt + ph - (v - lo) / (hi - lo) * ph;
  void grid(Canvas c, List<double> vs) {
    for (final v in vs) {
      final yy = y(v);
      c.drawLine(Offset(ml, yy), Offset(size.width - mr, yy), Paint()..color = v == 0 ? C.dim.withOpacity(.6) : C.line..strokeWidth = 1);
      _txt(c, eShort(v), Offset(ml - 6, yy), a: TextAlign.right);
    }
  }
}

(double, double) _range(List<double> vals, double pad) {
  var lo = math.min(0.0, vals.fold<double>(0, math.min));
  var hi = math.max(0.0, vals.fold<double>(0, math.max));
  if (hi == lo) hi = lo + 1;
  final p = (hi - lo) * pad;
  hi += p;
  if (lo < 0) lo -= p;
  return (lo, hi);
}

class ELinePainter extends CustomPainter {
  final List<String> labels;
  final List<double> vals;
  final Color col;
  final int step;
  final bool negDots;
  ELinePainter(this.labels, this.vals, this.col, {this.step = 1, this.negDots = false});
  @override
  void paint(Canvas c, Size size) {
    if (vals.isEmpty) return;
    final r = _range(vals, .12);
    final f = _Frame(size, r.$1, r.$2);
    f.grid(c, r.$1 < 0 ? [r.$2, 0, r.$1] : [r.$2, 0]);
    final n = vals.length;
    double x(int i) => f.ml + (n > 1 ? i / (n - 1) * f.pw : f.pw / 2);
    final path = Path();
    for (var i = 0; i < n; i++) {
      i == 0 ? path.moveTo(x(i), f.y(vals[i])) : path.lineTo(x(i), f.y(vals[i]));
    }
    final area = Path.from(path)..lineTo(x(n - 1), f.y(0))..lineTo(x(0), f.y(0))..close();
    c.drawPath(area, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [col.withOpacity(.4), col.withOpacity(0)]).createShader(Offset.zero & size));
    c.drawPath(path, Paint()..color = col..style = PaintingStyle.stroke..strokeWidth = 2.4..strokeJoin = StrokeJoin.round);
    for (var i = 0; i < n; i++) {
      if (negDots) {
        if (vals[i] < 0) c.drawCircle(Offset(x(i), f.y(vals[i])), 2.6, Paint()..color = kEBad);
      } else {
        c.drawCircle(Offset(x(i), f.y(vals[i])), i == n - 1 ? 5 : 3.5, Paint()..color = vals[i] < 0 ? kEBad : col);
      }
      if (i % step == 0) _txt(c, labels[i], Offset(x(i), size.height - 8), a: step > 1 && i == 0 ? TextAlign.left : TextAlign.center);
    }
    if (negDots) {
      var mi = 0;
      for (var i = 0; i < n; i++) {
        if (vals[i] < vals[mi]) mi = i;
      }
      final neg = vals[mi] < 0;
      c.drawCircle(Offset(x(mi), f.y(vals[mi])), 5, Paint()..color = neg ? kEBad : kGold2);
      _txt(c, eShort(vals[mi]), Offset(x(mi), f.y(vals[mi]) + (neg ? 16 : -10)), col: neg ? const Color(0xFFFF8F80) : kGold2, w: FontWeight.w700);
    } else {
      _txt(c, eShort(vals.last), Offset(x(n - 1) - 8, f.y(vals.last) - 12), a: TextAlign.right, col: col, w: FontWeight.w700);
    }
  }

  @override
  bool shouldRepaint(covariant ELinePainter o) => true;
}

class EBarsPainter extends CustomPainter {
  final List<String> labels;
  final List<(String, Color, List<double>)> series;
  final bool negRed;
  EBarsPainter(this.labels, this.series, {this.negRed = false});
  @override
  void paint(Canvas c, Size size) {
    final all = [for (final s in series) ...s.$3];
    final lo0 = negRed ? math.min(0.0, all.fold<double>(0, math.min)) : 0.0;
    final hi0 = math.max(0.0, all.fold<double>(0, math.max));
    var hi = negRed ? hi0 : eAxisMax(hi0 * 1.08);
    var lo = lo0;
    if (hi == lo) hi = lo + 1;
    if (negRed) {
      final p = (hi - lo) * .15;
      hi += p;
      if (lo < 0) lo -= p;
    }
    final f = _Frame(size, lo, hi);
    f.grid(c, negRed ? (lo < 0 ? [hi, 0, lo] : [hi, 0]) : [hi, hi / 2, 0]);
    final n = labels.length, k = series.length;
    final band = f.pw / n, bw = math.min(negRed ? 54.0 : 22.0, band * (negRed ? .6 : .7) / k);
    for (var j = 0; j < n; j++) {
      final cx = f.ml + band * j + band / 2, x0 = cx - (bw * k + (k - 1) * 2) / 2;
      for (var q = 0; q < k; q++) {
        final v = series[q].$3[j];
        if (v == 0 && !negRed) continue;
        final y0 = f.y(0), y1 = f.y(v);
        final top = math.min(y0, y1), hh = math.max(2.0, (y1 - y0).abs());
        final col = negRed ? (v < 0 ? kERed : j == 0 ? kGoldD : kGold) : series[q].$2;
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x0 + q * (bw + 2), top, bw, hh), const Radius.circular(5)), Paint()..color = col);
        if (negRed || size.width >= 430) _txt(c, eShort(v), Offset(x0 + q * (bw + 2) + bw / 2, v < 0 ? y1 + 12 : y1 - 8), col: v < 0 ? const Color(0xFFFF8F80) : kGold2, sz: 9.5, w: FontWeight.w700);
      }
      _txt(c, labels[j], Offset(cx, size.height - 8));
    }
  }

  @override
  bool shouldRepaint(covariant EBarsPainter o) => true;
}

class EBePainter extends CustomPainter {
  final EBE b;
  EBePainter(this.b);
  @override
  void paint(Canvas c, Size size) {
    final be = b.be!;
    final xmax = math.max(math.max(be * 1.7, b.rev * 1.15), 1.0);
    final ymax = eAxisMax(math.max(xmax, b.fixed + b.ratio * xmax) * 1.05);
    final f = _Frame(size, 0, ymax);
    double X(double v) => f.ml + v / xmax * f.pw;
    f.grid(c, [ymax, ymax / 2, 0]);
    for (var i = 0; i < 3; i++) {
      final v = xmax / 2 * i;
      _txt(c, eShort(v), Offset(X(v), size.height - 8), a: i == 0 ? TextAlign.left : i == 2 ? TextAlign.right : TextAlign.center);
    }
    c.drawLine(Offset(X(0), f.y(0)), Offset(X(xmax), f.y(xmax)), Paint()..color = kGold2..strokeWidth = 2.4);
    c.drawLine(Offset(X(0), f.y(b.fixed)), Offset(X(xmax), f.y(b.fixed + b.ratio * xmax)), Paint()..color = const Color(0xFFD6553D)..strokeWidth = 2.4);
    final bx = X(be), by = f.y(be);
    c.drawLine(Offset(bx, by), Offset(bx, f.y(0)), Paint()..color = kGold..strokeWidth = 1);
    c.drawCircle(Offset(bx, by), 6, Paint()..color = kGold);
    _txt(c, 'Zararsizlik ${eShort(be)}', Offset(bx, by - 12), a: bx > size.width - 90 ? TextAlign.right : TextAlign.center, col: kGold2, w: FontWeight.w700);
    if (b.rev > 0) {
      final rx = X(b.rev), ry = f.y(b.rev);
      c.drawCircle(Offset(rx, ry), 5, Paint()..color = Colors.white);
      _txt(c, 'Hozir', Offset(rx, ry + 16), a: rx > size.width - 70 ? TextAlign.right : TextAlign.center, col: C.ink, w: FontWeight.w700);
    }
  }

  @override
  bool shouldRepaint(covariant EBePainter o) => true;
}

class EGaugePainter extends CustomPainter {
  final int score;
  final Color col;
  EGaugePainter(this.score, this.col);
  @override
  void paint(Canvas c, Size size) {
    final ctr = size.center(Offset.zero);
    final r = size.width / 2 - 14;
    c.drawCircle(ctr, r, Paint()..color = const Color(0xFF1F1B10)..style = PaintingStyle.stroke..strokeWidth = 14);
    c.drawArc(Rect.fromCircle(center: ctr, radius: r), -math.pi / 2, 2 * math.pi * score / 100, false, Paint()..color = col..style = PaintingStyle.stroke..strokeWidth = 14..strokeCap = StrokeCap.round);
    _txt(c, '$score', ctr.translate(0, -2), col: col, sz: 46, w: FontWeight.w800);
    _txt(c, '100 DAN', ctr.translate(0, 26), col: const Color(0xFFA89F87), sz: 10, w: FontWeight.w700);
  }

  @override
  bool shouldRepaint(covariant EGaugePainter o) => o.score != score;
}

/* ====================================================================== */
/*  ELITE (UI)                                                             */
/* ====================================================================== */
const List<(String, String)> kETabs = [
  ('panel', 'Panel'), ('health', "Sog'lik"), ('cash', 'Pul oqimi'), ('cal', 'Kalendar'), ('age', 'Qarzdorlik'), ('be', 'Zararsizlik'), ('wi', 'Agar...?'),
  ('staff', 'Jamoa'), ('stock', 'Ombor'), ('plan', 'Reja va fakt'), ('inv', 'Hisob-faktura'), ('tx', 'Operatsiya'), ('rep', 'Hisobot'), ('co', 'Kompaniya'),
];

class EliteTab extends StatefulWidget {
  final ShellApi api;
  const EliteTab({super.key, required this.api});
  @override
  State<EliteTab> createState() => _EliteTabState();
}

class _EliteTabState extends State<EliteTab> {
  String tab = 'panel';
  String mon = monthKeyOf(DateTime.now());
  String eType = 'out', eCat = 'b_stock', eDate = todayStr(), eCoSel = '';
  bool expCal = true;
  final Map<String, double> W = {'p': 0, 'v': 0, 'c': 0, 'f': 0, 's': 0};
  final List<Map<String, dynamic>> draft = [];
  String idt = todayStr(), idu = '';
  final Map<String, TextEditingController> _c = {};
  final Map<String, String> _sel = {};

  Profile get p => app.profile!;
  TextEditingController ctl(String k, [String init = '']) => _c.putIfAbsent(k, () => TextEditingController(text: init));
  void _msg(String m) => toast(context, m);
  Future<void> _done([String? m]) async {
    await app.saveProfile();
    if (mounted) {
      setState(() {});
      if (m != null) _msg(m);
    }
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!p.isElite) {
      return ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Elite', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Biznesni boshqarish markazi: bir nechta kompaniya, pul oqimi prognozi, qarzdorlik yoshi, zararsizlik nuqtasi, xodimlar, ombor, reja va fakt, rahbar hisoboti.', style: TextStyle(color: C.dim)),
        const SizedBox(height: 16),
        PrimaryButton(label: "Elite ga o'tish", onTap: () => widget.api.show('plans')),
      ]);
    }
    final E = eInit();
    final cos = eL(E, 'cos');
    final head = <Widget>[
      const Text('Elite', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: kGold2)),
      const Text('Biznesni boshqarish markazi', style: TextStyle(color: C.dim, fontSize: 13.5)),
      const SizedBox(height: 12),
    ];
    if (cos.isEmpty) {
      return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
        ...head,
        uCard('Birinchi kompaniyani yarating', children: [
          uField(ctl('k-new'), 'Kompaniya nomi', max: 40),
          const SizedBox(height: 10),
          _gold('Yaratish', _addCo),
          uSmall("Keyin yana kompaniya qo'shib, har birini alohida yuritasiz va «Umumiy ko'rinish» da jamlab ko'rasiz."),
        ]),
      ]);
    }
    if (eCoSel.isEmpty || !cos.any((c) => c['id'] == eCoSel)) eCoSel = '${E['act'] != 'all' ? E['act'] : cos.first['id']}';
    final cats = _bzCats(eType);
    if (!cats.any((c) => c.id == eCat)) eCat = cats.first.id;
    final Widget body = switch (tab) {
      'health' => _health(),
      'cash' => _cash(),
      'cal' => _cal(),
      'age' => _age(),
      'be' => _be(),
      'wi' => _wi(),
      'staff' => _staff(),
      'stock' => _stock(),
      'plan' => _plan(),
      'inv' => _inv(),
      'tx' => _tx(),
      'rep' => _rep(),
      'co' => _co(),
      _ => _panel(),
    };
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
      ...head,
      SizedBox(
        height: 38,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          _chip("Umumiy ko'rinish", E['act'] == 'all', () {
            E['act'] = 'all';
            _done();
          }),
          for (final c in cos)
            _chip('${c['name']}', E['act'] == c['id'], () {
              E['act'] = c['id'];
              _done();
            }),
        ]),
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: 40,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (final t in kETabs)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(t.$2),
                selected: tab == t.$1,
                onSelected: (_) => setState(() => tab = t.$1),
                selectedColor: kGold.withOpacity(.22),
                backgroundColor: const Color(0x0AFFFFFF),
                side: BorderSide(color: tab == t.$1 ? kGold : C.line),
                labelStyle: TextStyle(color: tab == t.$1 ? kGold2 : C.dim, fontWeight: FontWeight.w700),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 14),
      body,
    ]);
  }

  /* ---------- small helpers ---------- */
  Widget _chip(String l, bool sel, VoidCallback f) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ActionChip(
          label: Text(l),
          onPressed: f,
          backgroundColor: sel ? kGold.withOpacity(.2) : const Color(0x0AFFFFFF),
          side: BorderSide(color: sel ? kGold : C.line),
          labelStyle: TextStyle(color: sel ? kGold2 : C.dim, fontWeight: FontWeight.w700),
        ),
      );

  Widget _gold(String l, VoidCallback f, {bool ghost = false}) => SizedBox(
        height: 46,
        child: ghost
            ? OutlinedButton(onPressed: f, style: OutlinedButton.styleFrom(side: const BorderSide(color: C.line), foregroundColor: C.ink, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: Text(l, style: const TextStyle(fontWeight: FontWeight.w700)))
            : FilledButton(onPressed: f, style: FilledButton.styleFrom(backgroundColor: kGold, foregroundColor: const Color(0xFF1A1405), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: Text(l, style: const TextStyle(fontWeight: FontWeight.w800))),
      );

  Widget _ek(List<(String, String, String, Color?)> k) {
    final rows = <Widget>[];
    for (var i = 0; i < k.length; i += 2) {
      rows.add(Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var j = i; j < math.min(i + 2, k.length); j++)
          Expanded(
            child: Container(
              margin: EdgeInsets.fromLTRB(j == i ? 0 : 4, 0, j == i ? 4 : 0, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color(0x0DD4AF37), border: Border.all(color: kGold.withOpacity(.25))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(k[j].$1, style: const TextStyle(color: C.dim, fontSize: 11.5)),
                const SizedBox(height: 4),
                FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(k[j].$2, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: k[j].$4 ?? kGold2))),
                const SizedBox(height: 2),
                Text(k[j].$3, style: const TextStyle(color: C.mute, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
            ),
          ),
        if (i + 1 >= k.length) const Expanded(child: SizedBox()),
      ]));
    }
    return Column(children: rows);
  }

  Widget _eal(String t, {bool bad = false, double sz = 13.5}) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: (bad ? kEBad : kGold).withOpacity(.1), border: Border.all(color: (bad ? kEBad : kGold).withOpacity(.4))),
        child: Text(t, style: TextStyle(fontSize: sz, height: 1.4)),
      );

  Widget _hero(double bal, String sub) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors: [Color(0xFF2A210A), Color(0xFF14100A)]), border: Border.all(color: kGold.withOpacity(.4))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Kassa va hisoblardagi mablag'", style: TextStyle(color: C.dim, fontSize: 12.5)),
          const SizedBox(height: 4),
          Text(sgn(bal), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: kGold2)),
          Text(sub, style: const TextStyle(color: C.dim, fontSize: 12.5)),
        ]),
      );

  Widget _chart(CustomPainter pt, {double h = 210}) => SizedBox(height: h, width: double.infinity, child: CustomPaint(painter: pt));
  Widget _legend(List<(String, Color)> l) => Padding(padding: const EdgeInsets.only(top: 8), child: Wrap(spacing: 14, children: [for (final x in l) Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: x.$2, borderRadius: BorderRadius.circular(3))), const SizedBox(width: 6), Text(x.$1, style: const TextStyle(color: C.dim, fontSize: 12))])]));

  Widget _monRow() => Center(child: MonthBar(mk: mon, onShift: (d) {
        final pp = mon.split('-');
        final nk = monthKeyOf(DateTime(int.parse(pp[0]), int.parse(pp[1]) + d, 1));
        if (nk.compareTo(monthKeyOf(DateTime.now())) > 0) return;
        setState(() => mon = nk);
      }));

  Widget _cb(String name, Color col, String val, double pct) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: col, shape: BoxShape.circle)), const SizedBox(width: 8), Expanded(child: Text(name, style: const TextStyle(fontSize: 13.5))), Text(val, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5))]),
          const SizedBox(height: 4),
          uBar(pct / 100, col),
        ]),
      );

  List<Cat> _bzCats(String t) {
    final l = catsOf(t);
    return [...l.where((c) => c.id.startsWith('b_')), ...l.where((c) => !c.id.startsWith('b_'))];
  }

  Widget _dd<T>(T value, List<(T, String)> items, ValueChanged<T> f) => DropdownButtonFormField<T>(
        value: value,
        isExpanded: true,
        dropdownColor: C.bg2,
        decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
        items: [for (final i in items) DropdownMenuItem(value: i.$1, child: Text(i.$2, overflow: TextOverflow.ellipsis))],
        onChanged: (v) {
          if (v != null) f(v);
        },
      );

  Widget _coField(String key) {
    final cos = eL(eInit(), 'cos');
    if (cos.length <= 1) return const SizedBox.shrink();
    final cur = _sel[key] ?? eCoSel;
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: _dd<String>(cos.any((c) => c['id'] == cur) ? cur : '${cos.first['id']}', [for (final c in cos) ('${c['id']}', '${c['name']}')], (v) => setState(() => _sel[key] = v)));
  }

  String _coId(String key) {
    final cos = eL(eInit(), 'cos');
    final cur = _sel[key] ?? eCoSel;
    return cos.any((c) => c['id'] == cur) ? cur : '${cos.first['id']}';
  }

  Widget _date(String v, ValueChanged<String> f, {String hint = ''}) => OutlinedButton(
        onPressed: () async {
          final d = await showDatePicker(context: context, initialDate: v.isEmpty ? DateTime.now() : parseDay(v), firstDate: DateTime(2000), lastDate: DateTime(2100));
          if (d != null) f(dayKey(d));
        },
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), side: const BorderSide(color: C.line), foregroundColor: v.isEmpty ? C.mute : C.ink),
        child: Text(v.isEmpty ? hint : v, overflow: TextOverflow.ellipsis),
      );

  Future<void> _addCo() async {
    final E = eInit();
    final nn = ctl('k-new').text.trim();
    if (nn.length < 2) return _msg('Kompaniya nomini kiriting.');
    if (eL(E, 'cos').length >= 10) return _msg("Eng ko'pi 10 ta kompaniya.");
    eL(E, 'cos').add({'id': nid(), 'name': nn.length > 40 ? nn.substring(0, 40) : nn, 'inn': '', 'phone': '', 'req': '', 'tax': 0.0, 'cash': 0.0, 'fixed': 0.0, 'inv': [], 'staff': [], 'stock': [], 'plan': {}, 'tl': []});
    ctl('k-new').clear();
    await _done('Kompaniya qo\'shildi');
  }

  Future<void> _addTx(Tx t) => app.addTx(t);

  /* ---------- PANEL ---------- */
  Widget _panel() {
    final E = eInit();
    final cos = eVis();
    final s = eMon(mon), ps = eMon(prevMonthKey(mon));
    final pf = eProf(s), bal = eBal(cos), ag = eAge(), net = s.i - s.o;
    final dv = ps.i > 0 ? ((s.i - ps.i) / ps.i * 100).round() : null;
    final mg = s.i > 0 ? (pf / s.i * 100).round() : null;
    final hq = eHealth();
    final al = eAlerts();
    final ks = <String>[];
    var m = mon;
    for (var i = 0; i < 6; i++) {
      ks.insert(0, m);
      m = prevMonthKey(m);
    }
    final ss = ks.map(eMon).toList();
    final lb = ks.map((k) => kM3(int.parse(k.substring(5, 7)))).toList();
    final cats = s.bo.keys.toList()..sort((a, b) => s.bo[b]!.compareTo(s.bo[a]!));
    final pl = ks.map((k) => cos.fold<double>(0, (a, c) => a + nd(eM(eM(c, 'plan'), k)['rev']))).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _hero(bal, E['act'] == 'all' ? "Umumiy ko'rinish · ${cos.length} ta kompaniya" : '${cos.first['name']}'),
      _quickTx(),
      _monRow(),
      _ek([
        ('Tushum', mny(s.i), dv == null ? "O'tgan oyda ma'lumot yo'q" : "${dv >= 0 ? '↑ +' : '↓ −'}${dv.abs()}% o'tgan oyga nisbatan", null),
        ('Foyda', sgn(pf), mg == null ? "Tushum yo'q" : 'Marja $mg%', pf < 0 ? C.out : null),
        ('Qarzdorlik', mny(ag.tot), ag.o7 > 0 ? "7 kundan oshgan: ${mny(ag.o7)}" : "Kechikkan qarz yo'q", ag.o7 > 0 ? C.warn : null),
        ('Pul oqimi', sgn(net), 'Kirim − chiqim', net < 0 ? C.out : null),
      ]),
      if (hq.has)
        uCard("Sog'lik balli · ${hq.lab}", children: [
          Row(children: [
            Text('${hq.score}', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: hq.col)),
            const SizedBox(width: 14),
            Expanded(child: Text(hq.msg, style: const TextStyle(color: C.dim, fontSize: 12.5, height: 1.4))),
          ]),
          TextButton(onPressed: () => setState(() => tab = 'health'), child: const Text('Batafsil', style: TextStyle(color: kGold2))),
        ]),
      if (al.isNotEmpty) uCard('Diqqat', children: [for (final x in al) _eal(x.t, bad: x.r)]),
      uCard('Foyda trendi', sub: '6 oy', children: [_chart(ELinePainter(lb, ss.map(eProf).toList(), kGold))]),
      uCard('Pul oqimi', sub: '6 oy', children: [_chart(EBarsPainter(lb, [('Kirim', kGold, ss.map((x) => x.i).toList()), ('Chiqim', const Color(0xFFC9553D), ss.map((x) => x.o).toList())]), h: 220), _legend(const [('Kirim', kGold), ('Chiqim', Color(0xFFC9553D))])]),
      uCard('Xarajat tuzilmasi', sub: mlab(mon), children: [
        if (cats.isEmpty) uSmall("Bu oyda xarajat yo'q."),
        for (final k in cats) _cb(catOf('out', k).name, catOf('out', k).color, '${mny(s.bo[k]!)} · ${(s.bo[k]! / s.o * 100).round()}%', s.bo[k]! / s.o * 100),
      ]),
      uCard('Reja va fakt', sub: 'tushum, 6 oy', children: [
        if (!pl.any((v) => v > 0)) uSmall("Reja belgilanmagan. «Reja va fakt» bo'limida oylik maqsad kiriting.") else ...[_chart(EBarsPainter(lb, [('Reja', kGoldD, pl), ('Fakt', kGold2, ss.map((x) => x.i).toList())]), h: 220), _legend(const [('Reja', kGoldD), ('Fakt', kGold2)])],
      ]),
      if (E['act'] == 'all' && eL(E, 'cos').length > 1)
        uCard("Kompaniyalar bo'yicha", sub: mlab(mon), children: [
          for (final c in eL(E, 'cos'))
            Builder(builder: (_) {
              final cs = eSum(app.listOf(mon).where((x) => x.ex['e'] == c['id']));
              final cr = eL(c, 'inv').fold<double>(0, (a, v) => a + math.max(0, nd(v['total']) - nd(v['paid'])));
              return URow(title: '${c['name']}', sub: 'Tushum ${mny(cs.i)} · Qarz ${mny(cr)} · Kassa ${sgn(eBal([c]))}', amount: sgn(eProf(cs)), amountColor: eProf(cs) < 0 ? C.out : C.accent);
            }),
        ]),
    ]);
  }

  Widget _quickTx() => uCard('Tez kirim / chiqim', sub: "shu yerning o'zida", children: _txForm());

  List<Widget> _txForm() {
    final cats = _bzCats(eType);
    return [
      _coField('et-co'),
      Row(children: [
        Expanded(child: _dd<String>(eType, const [('out', 'Chiqim'), ('in', 'Kirim')], (v) => setState(() {
              eType = v;
              eCat = _bzCats(v).first.id;
            }))),
        const SizedBox(width: 8),
        Expanded(child: uField(ctl('et-a'), 'Summa', num: true)),
      ]),
      const SizedBox(height: 8),
      _dd<String>(cats.any((c) => c.id == eCat) ? eCat : cats.first.id, [for (final c in cats) (c.id, c.name)], (v) => setState(() => eCat = v)),
      const SizedBox(height: 8),
      Row(children: [Expanded(child: uField(ctl('et-n'), 'Izoh', max: 60)), const SizedBox(width: 8), Expanded(child: _date(eDate, (d) => setState(() => eDate = d)))]),
      const SizedBox(height: 10),
      _gold("Qo'shish", () async {
        final c0 = eCo(_coId('et-co'));
        final am = parseAmount(ctl('et-a').text);
        if (c0 == null) return _msg('Kompaniyani tanlang.');
        if (am == null || am <= 0 || am > 1e12) return _msg("Summani to'g'ri kiriting.");
        final a = fixAmt(am);
        await _addTx(Tx(id: newId(), t: eType, a: a, c: eCat, n: ctl('et-n').text.trim(), d: eDate, ts: DateTime.now().millisecondsSinceEpoch, ex: {'e': c0['id']}));
        ctl('et-a').clear();
        ctl('et-n').clear();
        mon = eDate.substring(0, 7).compareTo(monthKeyOf(DateTime.now())) > 0 ? monthKeyOf(DateTime.now()) : eDate.substring(0, 7);
        if (mounted) {
          setState(() {});
          _msg('${eType == 'in' ? 'Kirim: +' : 'Chiqim: −'}${grp(a)} ${curUnit()}');
        }
      }),
    ];
  }

  /* ---------- HEALTH ---------- */
  Widget _health() {
    final q = eHealth();
    if (!q.has) return uCard("Biznes sog'lik balli", children: [uSmall("Ball uchun ma'lumot kerak: kamida bir oylik tushum va xarajat. «Operatsiya» bo'limidan kiriting.")]);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      uCard('${q.lab}', children: [
        Row(children: [
          SizedBox(width: 150, height: 150, child: CustomPaint(painter: EGaugePainter(q.score, q.col))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(q.msg, style: const TextStyle(height: 1.4)), const SizedBox(height: 8), Text("Ball ${q.comps.length} ta ko'rsatkichga asoslangan. Bu taxminiy baho, rasmiy xulosa emas.", style: const TextStyle(color: C.dim, fontSize: 12))])),
        ]),
      ]),
      uCard("Ko'rsatkichlar", sub: 'har biri 100 balldan', children: [
        for (final c in q.comps)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: Text('${c.l}  · ahamiyati ${c.w}%', style: const TextStyle(fontSize: 13.5))), Text('${c.s} / 100', style: const TextStyle(fontWeight: FontWeight.w800))]),
              const SizedBox(height: 4),
              uBar(c.s / 100, eHL(c.s).$2),
              const SizedBox(height: 4),
              Text('${c.t}${c == q.weak && c.s < 80 ? ' · ${c.adv}' : ''}', style: const TextStyle(color: C.dim, fontSize: 12)),
            ]),
          ),
      ]),
    ]);
  }

  /* ---------- CASH ---------- */
  Widget _cash() {
    final f = eFore(), ag = eAge();
    if (!f.has) return uCard('Pul oqimi prognozi', children: [uSmall("Prognoz uchun kamida bitta oylik operatsiya, xodim yoki doimiy xarajat kerak. «Operatsiya» bo'limidan kiriting.")]);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _ek([
        ('Hozirgi kassa', sgn(f.bal), "Boshlang'ich qoldiq + operatsiyalar", f.bal < 0 ? C.out : null),
        ("O'rtacha kirim", mny(f.ai), 'Oyiga, oxirgi ${f.n} oy', null),
        ("O'rtacha chiqim", mny(f.ao + f.pay + f.fx), 'Ish haqi va doimiy xarajat bilan', null),
        ('Oylik sof oqim', sgn(f.net), f.net < 0 ? 'Kassa kamayyapti' : "Kassa o'syapti", f.net < 0 ? C.out : null),
      ]),
      _eal(f.sh != null ? '${f.sh}. Tushumni oshirish yoki xarajatni kamaytirish kerak.' : 'Keyingi 3 oyda pul tanqisligi kutilmaydi.', bad: f.sh != null, sz: 15),
      uCard('Kassa prognozi', sub: 'oy oxiridagi qoldiq', children: [_chart(EBarsPainter(f.pts.map((x) => x.$1).toList(), [('Kassa', kGold, f.pts.map((x) => x.$2).toList())], negRed: true), h: 230)]),
      uCard('Hisob-kitob asosi', sub: 'oylik', children: [
        URow(title: "O'rtacha kirim", sub: "Oxirgi 3 oyning o'rtachasi", amount: '+${mny(f.ai)}'),
        URow(title: "O'rtacha chiqim", sub: 'Ish haqidan tashqari', amount: '−${mny(f.ao)}'),
        URow(title: 'Xodimlar ish haqi', sub: "Jamoa bo'limidagi maoshlar yoki o'rtacha", amount: '−${mny(f.pay)}'),
        URow(title: "Qo'shimcha doimiy xarajat", sub: 'Kompaniya sozlamalaridan', amount: '−${mny(f.fx)}'),
        URow(title: 'Sof oylik oqim', amount: sgn(f.net), amountColor: f.net < 0 ? C.out : C.accent),
        NoteBox("Hisob-fakturalar bo'yicha kutilayotgan to'lovlar: ${mny(ag.tot)}. Ular o'rtacha kirimga qo'shilmagan, to'lov kelsa prognoz yaxshilanadi. Bu taxminiy hisob."),
      ]),
    ]);
  }

  /* ---------- CALENDAR ---------- */
  Widget _cal() {
    final c = eCal(expCal);
    if (!c.hasData) return uCard('Pul yetmaydigan kun', children: [uSmall("Kalendar uchun ma'lumot kerak: kassa qoldig'i, xodimlar, soliq muddatlari yoki hisob-fakturalar. «Kompaniya», «Jamoa» va «Operatsiya» bo'limlaridan kiriting.")]);
    final rows = c.days.where((x) => x.ev.isNotEmpty).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: _modeBtn('Kutilayotgan savdo bilan', expCal, () => setState(() => expCal = true))),
        const SizedBox(width: 8),
        Expanded(child: _modeBtn("Faqat ma'lum to'lovlar", !expCal, () => setState(() => expCal = false))),
      ]),
      const SizedBox(height: 10),
      _ek([
        ('Hozirgi kassa', sgn(c.bal), "Boshlang'ich qoldiq + operatsiyalar", c.bal < 0 ? C.out : null),
        ('Birinchi tanqislik', c.first != null ? eDL(c.first!.d) : "Yo'q", c.first != null ? 'Qoldiq ${sgn(c.first!.v)}' : "Keyingi 60 kunda manfiy emas", c.first != null ? C.out : C.accent),
        ('Eng past qoldiq', sgn(c.min.v), eDL(c.min.d), c.min.v < 0 ? C.out : null),
        ("Ma'lum chiqimlar", mny(c.out), 'Keyingi 60 kun', null),
      ]),
      if (c.first != null) ...[
        _eal("${eDL(c.first!.d)} kuni${c.first!.ev.where((x) => x.a < 0).isNotEmpty ? ': ${c.first!.ev.where((x) => x.a < 0).map((x) => '${x.n} (${mny(-x.a)})').join(', ')} to\'lanadi, ' : ', '}kassada pul yetmaydi. Qoldiq ${sgn(c.first!.v)}.", bad: true, sz: 15),
        if (c.res.isNotEmpty && c.cover) _eal("Kechikkan qarzlarni undirsangiz tanqislik yopiladi: ${c.res.map((x) => '${x.c} (${mny(x.d)})').join(', ')}.") else _eal("${c.odTot > 0 ? 'Kechikkan qarzlar (${mny(c.odTot)}) ham yetmaydi. ' : ''}Tanqislikni yopish uchun yana taxminan ${mny(c.need - c.odTot > 0 ? c.need - c.odTot : c.need)} kerak: tushumni oshiring yoki to'lovlarni suring.", bad: true),
      ] else
        _eal("Keyingi 60 kunda kassa manfiyga tushmaydi. Eng past qoldiq: ${sgn(c.min.v)} (${eDL(c.min.d)}).", sz: 15),
      uCard('Kassa', sub: 'keyingi 60 kun', children: [_chart(ELinePainter(c.days.map((x) => eDL(x.d)).toList(), c.days.map((x) => x.v).toList(), kGold, step: 10, negDots: true), h: 230)]),
      uCard("To'lovlar kalendari", children: [
        if (rows.isEmpty) uSmall("Keyingi 60 kunda to'lov yo'q. Ish haqi kuni, soliq muddati va doimiy xarajatlarni «Jamoa» va «Kompaniya» bo'limlarida kiriting."),
        for (final x in rows) URow(title: eDL(x.d), sub: x.ev.map((e) => '${e.n}${e.a != 0 ? ' · ${sdn(e.a)}' : ''}').join('\n'), amount: '${sgn(x.v)}\nqoldiq', amountColor: x.v < 0 ? C.out : null, late: x.v < 0),
        uSmall("«Kutilayotgan savdo» rejimida oxirgi 3 oy o'rtacha sof savdosi kunlarga bo'lib qo'shiladi. «Faqat ma'lum to'lovlar» rejimida faqat chiqimlar va hisob-fakturalar muddati hisobga olinadi. Kechikkan qarzlar hech qaysi rejimda kirim sifatida olinmaydi."),
      ]),
    ]);
  }

  Widget _modeBtn(String l, bool on, VoidCallback f) => OutlinedButton(onPressed: f, style: OutlinedButton.styleFrom(side: BorderSide(color: on ? kGold : C.line), backgroundColor: on ? kGold.withOpacity(.15) : null, foregroundColor: on ? kGold2 : C.dim, padding: const EdgeInsets.symmetric(vertical: 12)), child: Text(l, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)));

  /* ---------- AGING ---------- */
  Widget _age() {
    final cos = eVis();
    final ag = eAge();
    final t = ag.t;
    final cm = <String, Map<String, dynamic>>{};
    for (final c in cos) {
      for (final v in eL(c, 'inv')) {
        final k = '${v['client']}'.trim().toLowerCase();
        final o = cm.putIfAbsent(k, () => {'name': '${v['client']}'.trim(), 'n': 0, 'tot': 0.0, 'paid': 0.0, 'old': -9999});
        o['n'] = (o['n'] as int) + 1;
        o['tot'] = (o['tot'] as double) + nd(v['total']);
        o['paid'] = (o['paid'] as double) + nd(v['paid']);
        if (nd(v['total']) - nd(v['paid']) > .001) {
          final dd = eDays('${v['due'] ?? ''}'.isNotEmpty ? '${v['due']}' : '${v['date']}');
          if (dd > (o['old'] as int)) o['old'] = dd;
        }
      }
    }
    final cr = cm.values.toList()..sort((a, b) => ((b['tot'] as double) - (b['paid'] as double)).compareTo((a['tot'] as double) - (a['paid'] as double)));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _ek([
        ('Jami qarzdorlik', mny(ag.tot), '${ag.rows.length} ta hisob-faktura', null),
        ('7 kundan oshgan', mny(t[2] + t[3] + t[4]), "8 kun va undan ko'p", t[2] + t[3] + t[4] > 0 ? C.warn : null),
        ('30 kundan oshgan', mny(t[3] + t[4]), "31 kun va undan ko'p", t[3] + t[4] > 0 ? kEBad : null),
        ('60 kundan oshgan', mny(t[4]), 'Xavfli qarz', t[4] > 0 ? kERed : null),
      ]),
      uCard('Qarzdorlik yoshi', sub: "to'lov muddatidan boshlab", children: [
        if (ag.tot <= 0) uSmall("Qarzdorlik yo'q. Hisob-faktura bo'limida hisob-faktura yarating.") else for (var i = 0; i < 5; i++) _cb(kAgeB[i].$1, kAgeB[i].$2, '${mny(t[i])} · ${ag.n[i]} ta', t[i] / ag.tot * 100),
      ]),
      if (ag.rows.isNotEmpty)
        uCard("Kechikkan va kutilayotgan to'lovlar", children: [
          for (final r in ag.rows) URow(title: '${r.v['client']}', sub: '${r.v['no']}${eTag(r.c)} · ${r.days > 0 ? '${r.days} kun kechikkan' : r.days == 0 ? 'bugun muddati' : '${-r.days} kundan keyin'}', amount: mny(r.d), amountColor: kAgeB[r.i].$2, late: r.days > 7),
        ]),
      uCard('Mijozlar daftari', children: [
        if (cr.isEmpty) uSmall('Mijozlar hisob-fakturalardan avtomatik shakllanadi.'),
        for (final c in cr)
          Builder(builder: (_) {
            final d = fixAmt((c['tot'] as double) - (c['paid'] as double));
            final old = c['old'] as int;
            return URow(title: '${c['name']}', sub: "${c['n']} ta hisob-faktura · jami ${mny(c['tot'] as double)} · to'lagan ${mny(c['paid'] as double)}", amount: d > 0 ? '${mny(d)}\nqarz' : '✓', amountColor: old > 60 ? kERed : old > 30 ? kEBad : old > 7 ? C.warn : null, late: d > 0 && old > 7);
          }),
      ]),
    ]);
  }

  /* ---------- BREAK-EVEN ---------- */
  Widget _be() {
    final b = eBE();
    if (!b.has) return uCard('Zararsizlik nuqtasi', children: [uSmall("Hisob uchun joriy yoki o'tgan oylarda tushum kerak. Doimiy xarajatlar (ijara, ish haqi) operatsiyalardan, Jamoa va Kompaniya bo'limlaridan olinadi.")]);
    if (b.be == null) return uCard('Zararsizlik nuqtasi', children: [_eal("O'zgaruvchan xarajat tushumdan oshib ketgan: har bir sotuvdan zarar qilyapsiz. Narx yoki tannarxni qayta ko'ring.", bad: true)]);
    final be = b.be!;
    final pc = be > 0 ? math.min(1.0, b.rev / be) : 1.0;
    final now = DateTime.now();
    final dl = daysIn(now.year, now.month) - now.day + 1;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _ek([
        ('Zararsizlik nuqtasi', mny(be), "Oyiga shuncha sotsangiz zarar bo'lmaydi", null),
        ('Joriy oy tushumi', mny(b.rev), be > 0 ? "${(b.rev / be * 100).round()}% zararsizlik nuqtasidan" : '—', b.rev >= be ? C.accent : null),
        ('Doimiy xarajat', mny(b.fixed), "Ijara, ish haqi va boshqa", null),
        ('Hissa marjasi', '${(b.cm * 100).round()}%', "Har 100 so'm tushumdan qoladi", null),
      ]),
      uCard('Joriy oy holati', sub: mlab(monthKeyOf(now)), children: [
        uBar(pc, b.rev >= be ? C.accent : kGold),
        const SizedBox(height: 8),
        NoteBox(b.rev >= be ? "Zararsizlik nuqtasidan ${mny(b.rev - be)} yuqorisiz. Bu oy foydali." : "Zararsizlik uchun yana ${mny(be - b.rev)} sotish kerak. Oy oxirigacha $dl kun, kuniga taxminan ${mny((be - b.rev) / dl)}."),
      ]),
      uCard('Zararsizlik grafigi', children: [
        _chart(EBePainter(b), h: 240),
        _legend(const [('Tushum', kGold2), ('Jami xarajat', Color(0xFFD6553D))]),
        uSmall("Chiziqlar kesishgan joy zararsizlik nuqtasi. Hisob: doimiy xarajat ÷ (1 − o'zgaruvchan xarajat ulushi), oxirgi 3 oy asosida."),
      ]),
    ]);
  }

  /* ---------- WHAT-IF ---------- */
  Widget _wi() {
    final b = eBase();
    if (b.n == 0) return uCard('«Agar...?» mashinasi', children: [uSmall("Hisob uchun kamida bir oylik tushum kerak. «Operatsiya» bo'limidan kiriting.")]);
    final S = <(String, String, double, double, String)>[
      ('p', 'Sotuv narxi', -30, 30, '%'),
      ('v', 'Sotuv hajmi', -50, 50, '%'),
      ('c', "O'zgaruvchan xarajat (tannarx)", -30, 30, '%'),
      ('f', 'Doimiy xarajat (ijara va boshqa)', -50, 50, '%'),
      if (b.avgSal > 0) ('s', 'Xodimlar soni', -5, 5, ' kishi'),
    ];
    final w = W;
    final rev0 = b.rev, vc0 = rev0 * b.ratio, fx0 = b.rent + b.pay + b.fx;
    final rev1 = rev0 * (1 + w['p']! / 100) * (1 + w['v']! / 100), vc1 = vc0 * (1 + w['v']! / 100) * (1 + w['c']! / 100);
    final fx1 = (b.rent + b.fx) * (1 + w['f']! / 100) + math.max(0, b.pay + (b.avgSal > 0 ? w['s']! * b.avgSal : 0));
    final pf0 = rev0 - vc0 - fx0, pf1 = rev1 - vc1 - fx1, cm1 = rev1 > 0 ? 1 - vc1 / rev1 : 0, cm0 = 1 - b.ratio;
    final d = pf1 - pf0;
    final be0 = cm0 > 0 ? fx0 / cm0 : null, be1 = cm1 > 0 ? fx1 / cm1 : null;
    final mg0 = rev0 > 0 ? pf0 / rev0 * 100 : null, mg1 = rev1 > 0 ? pf1 / rev1 * 100 : null;
    final f0 = eFore(0), f1 = eFore(d);
    final e1 = f1.pts[3].$2, e0 = f0.pts[3].$2;
    Widget row(String a, double x, double y) => URow(title: a, sub: 'Hozir: ${mny(fixAmt(x))}', amount: mny(fixAmt(y)));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      uCard('Sozlang', sub: "natija darhol o'zgaradi", children: [
        for (final x in S)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: Text(x.$2, style: const TextStyle(fontSize: 13.5))), Text('${w[x.$1]! > 0 ? '+' : ''}${w[x.$1]!.round()}${x.$5}', style: const TextStyle(fontWeight: FontWeight.w800, color: kGold2))]),
              Slider(value: w[x.$1]!, min: x.$3, max: x.$4, divisions: (x.$4 - x.$3).round(), activeColor: kGold, onChanged: (v) => setState(() => w[x.$1] = v.roundToDouble())),
            ]),
          ),
        _gold("Boshlang'ich holatga qaytarish", () => setState(() => W.updateAll((k, v) => 0)), ghost: true),
        uSmall("Asos: oxirgi 3 oyning o'rtachasi. Narx o'zgarganda sotuv hajmi o'zgarmaydi deb olinadi. Hajmni alohida surib ko'ring."),
      ]),
      _ek([
        ('Oylik foyda', sgn(fixAmt(pf1)), 'Hozir: ${sgn(fixAmt(pf0))} · ${sdn(fixAmt(d))}', pf1 < 0 ? C.out : null),
        ('Marja', mg1 == null ? '—' : '${mg1.round()}%', 'Hozir: ${mg0 == null ? '—' : '${mg0.round()}%'}', null),
        ('Zararsizlik nuqtasi', be1 == null ? '—' : mny(fixAmt(be1)), 'Hozir: ${be0 == null ? '—' : mny(fixAmt(be0))}', null),
        ('3 oydan keyin kassa', sgn(e1), 'Hozirgi prognoz: ${sgn(e0)}', e1 < 0 ? C.out : null),
      ]),
      _eal('${f1.sh != null ? '${f1.sh}.' : 'Bu ssenariyda 3 oy ichida pul tanqisligi kutilmaydi.'}${f0.sh != null && f1.sh == null ? " Hozirgi holatda tanqislik bor edi, bu o'zgarish uni yopadi." : ''}', bad: f1.sh != null, sz: 15),
      uCard('Oylik hisob', sub: 'ssenariy', children: [
        row('Tushum', rev0, rev1),
        row("O'zgaruvchan xarajat", vc0, vc1),
        row('Doimiy xarajat va ish haqi', fx0, fx1),
        URow(title: 'Foyda', sub: 'Hozir: ${sgn(fixAmt(pf0))}', amount: sgn(fixAmt(pf1)), amountColor: pf1 < 0 ? C.out : C.accent),
      ]),
    ]);
  }

  /* ---------- STAFF ---------- */
  Widget _staff() {
    final cos = eVis();
    final cm = monthKeyOf(DateTime.now());
    var tot = 0.0, paid = 0.0, n = 0;
    for (final c in cos) {
      for (final x in eL(c, 'staff')) {
        n++;
        tot += nd(x['sal']);
        final pa = x['paid'];
        if (pa is Map && pa[cm] != null) paid += nd(x['sal']);
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _ek([
        ('Ish haqi fondi', mny(tot), 'Oyiga', null),
        ("Shu oy to'landi", mny(paid), mlab(cm), null),
        ("To'lanishi kerak", mny(tot - paid), tot - paid > 0 ? 'Qolgan' : "Hammasi to'langan", tot - paid > 0 ? C.warn : null),
        ('Xodimlar', '$n', 'Jami', null),
      ]),
      uCard("Xodim qo'shish", children: [
        _coField('st-co'),
        Row(children: [Expanded(child: uField(ctl('st-n'), 'Ism', max: 40)), const SizedBox(width: 8), Expanded(child: uField(ctl('st-r'), 'Lavozim', max: 40))]),
        const SizedBox(height: 8),
        Row(children: [Expanded(child: uField(ctl('st-s'), 'Oylik maosh', num: true)), const SizedBox(width: 8), Expanded(child: uField(ctl('st-d'), "To'lov kuni (1-31)", kt: TextInputType.number))]),
        const SizedBox(height: 10),
        _gold("Qo'shish", () {
          final c1 = eCo(_coId('st-co'));
          final sl = parseAmount(ctl('st-s').text), sd = parseAmount(ctl('st-d').text)?.round();
          final sn = ctl('st-n').text.trim();
          if (c1 == null) return _msg('Kompaniyani tanlang.');
          if (sn.length < 2) return _msg('Ismni kiriting.');
          if (sl == null || sl <= 0) return _msg('Maoshni kiriting.');
          if (sd == null || sd < 1 || sd > 31) return _msg("Kun 1 dan 31 gacha bo'lsin.");
          eL(c1, 'staff').add({'id': nid(), 'name': sn, 'role': ctl('st-r').text.trim(), 'sal': fixAmt(sl), 'day': sd, 'paid': {}});
          for (final k in ['st-n', 'st-r', 'st-s', 'st-d']) {
            ctl(k).clear();
          }
          _done("Xodim qo'shildi");
        }),
      ]),
      uCard('Xodimlar va ish haqi', sub: mlab(cm), children: [
        if (n == 0) uSmall("Hali xodim yo'q. «To'landi» bosilsa, ish haqi xarajat sifatida yoziladi."),
        for (final c in cos)
          for (final x in eL(c, 'staff'))
            Builder(builder: (_) {
              final s = eStaffSt(x);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: s.s == 'late' ? C.out.withOpacity(.08) : const Color(0x08FFFFFF), border: Border.all(color: s.s == 'late' ? C.out.withOpacity(.4) : C.line)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${x['name']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text.rich(TextSpan(style: const TextStyle(color: C.dim, fontSize: 12.5), children: [TextSpan(text: '${'${x['role'] ?? ''}'.isEmpty ? 'Xodim' : x['role']}${eTag(c)} · har oy ${x['day']}-kuni · '), TextSpan(text: s.l, style: TextStyle(color: s.s == 'paid' ? C.accent : s.s == 'late' ? C.out : C.dim))])),
                    ])),
                    Text(mny(nd(x['sal'])), style: const TextStyle(fontWeight: FontWeight.w800)),
                  ]),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    if (s.s != 'paid')
                      TextButton(
                        onPressed: () async {
                          final pa = eM(x, 'paid');
                          if (pa[cm] != null) return;
                          final a = fixAmt(nd(x['sal']));
                          pa[cm] = todayStr();
                          await _addTx(Tx(id: newId(), t: 'out', a: a, c: 'b_pay', n: 'Ish haqi: ${x['name']}', d: todayStr(), ts: DateTime.now().millisecondsSinceEpoch, ex: {'e': c['id']}));
                          await _done("Ish haqi to'landi: −${grp(a)} ${curUnit()}");
                        },
                        child: const Text("To'landi", style: TextStyle(color: kGold2, fontWeight: FontWeight.w700)),
                      ),
                    SureBtn(onSure: () {
                      c['staff'] = eL(c, 'staff').where((y) => y['id'] != x['id']).toList();
                      _done();
                    }),
                  ]),
                ]),
              );
            }),
      ]),
    ]);
  }

  /* ---------- STOCK ---------- */
  Widget _stock() {
    final cos = eVis();
    var val = 0.0, pot = 0.0, cnt = 0, low = 0, pfit = 0.0;
    for (final c in cos) {
      for (final q in eL(c, 'stock')) {
        val += nd(q['qty']) * nd(q['cost']);
        pot += nd(q['qty']) * nd(q['price']);
        cnt++;
        pfit += nd(q['profit']);
        if (nd(q['min']) > 0 && nd(q['qty']) <= nd(q['min'])) low++;
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _ek([
        ('Ombor qiymati', mny(val), "Tannarx bo'yicha", null),
        ('Sotuv qiymati', mny(pot), 'Sotuv narxida', null),
        ('Sotuvdan foyda', mny(pfit), 'Sotilgan mahsulotlardan', null),
        ('Mahsulotlar', '$cnt', low > 0 ? '$low tasi tugayapti' : 'Qoldiq yetarli', low > 0 ? C.warn : null),
      ]),
      uCard("Mahsulot qo'shish", children: [
        _coField('sk-co'),
        uField(ctl('sk-n'), 'Mahsulot nomi', max: 50),
        const SizedBox(height: 8),
        Row(children: [Expanded(child: uField(ctl('sk-q'), 'Qoldiq (soni)', num: true)), const SizedBox(width: 8), Expanded(child: uField(ctl('sk-m'), 'Minimal qoldiq', num: true))]),
        const SizedBox(height: 8),
        Row(children: [Expanded(child: uField(ctl('sk-c'), 'Tannarx (1 dona)', num: true)), const SizedBox(width: 8), Expanded(child: uField(ctl('sk-p'), 'Sotuv narxi (1 dona)', num: true))]),
        const SizedBox(height: 10),
        _gold("Qo'shish", () {
          final c2 = eCo(_coId('sk-co'));
          final nm = ctl('sk-n').text.trim();
          final q = ctl('sk-q').text.trim().isEmpty ? 0.0 : parseAmount(ctl('sk-q').text);
          final mn = ctl('sk-m').text.trim().isEmpty ? 0.0 : parseAmount(ctl('sk-m').text);
          final cs = ctl('sk-c').text.trim().isEmpty ? 0.0 : parseAmount(ctl('sk-c').text);
          final pr = parseAmount(ctl('sk-p').text);
          if (c2 == null) return _msg('Kompaniyani tanlang.');
          if (nm.length < 2) return _msg('Mahsulot nomini kiriting.');
          if (q == null || mn == null || q < 0 || mn < 0) return _msg('Sonni raqam bilan kiriting.');
          if (cs == null || cs < 0) return _msg('Tannarxni kiriting.');
          if (pr == null || pr <= 0) return _msg('Sotuv narxini kiriting.');
          eL(c2, 'stock').add({'id': nid(), 'name': nm, 'qty': q, 'min': mn, 'cost': r2(cs), 'price': r2(pr), 'sold': 0, 'profit': 0.0});
          for (final k in ['sk-n', 'sk-q', 'sk-m', 'sk-c', 'sk-p']) {
            ctl(k).clear();
          }
          _done("Mahsulot qo'shildi");
        }),
      ]),
      uCard('Ombor', children: [
        if (cnt == 0) uSmall("Hali mahsulot yo'q. «Sotish» kirim va tannarxni, «Xarid» chiqimni avtomatik yozadi."),
        for (final c in cos) for (final q in eL(c, 'stock')) _stockRow(c, q),
        uSmall('Foyda hisobida sotilgan tovarning tannarxi (xarid summasi emas) hisobga olinadi.'),
      ]),
    ]);
  }

  Widget _stockRow(Map<String, dynamic> c, Map<String, dynamic> q) {
    final id = '${q['id']}';
    final mg = nd(q['price']) > 0 ? ((nd(q['price']) - nd(q['cost'])) / nd(q['price']) * 100).round() : 0;
    final lw = nd(q['min']) > 0 && nd(q['qty']) <= nd(q['min']);
    final qc = ctl('s-q-$id'), cc = ctl('s-c-$id');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color(0x08FFFFFF), border: Border.all(color: lw ? C.warn.withOpacity(.5) : C.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${q['name']}${lw ? '  · tugayapti' : ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('Qoldiq: ${nd(q['qty']) % 1 == 0 ? nd(q['qty']).toInt() : nd(q['qty'])} · Tannarx ${mny(nd(q['cost']))} · Narx ${mny(nd(q['price']))} · Marja $mg%${eTag(c)}', style: const TextStyle(color: C.dim, fontSize: 12.5)),
            Text('Sotilgan: ${q['sold'] ?? 0} · Foyda: ${mny(nd(q['profit']))}', style: const TextStyle(color: C.dim, fontSize: 12.5)),
          ])),
          Text(mny(nd(q['qty']) * nd(q['cost'])), style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: SizedBox(height: 38, child: TextField(controller: qc, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(fontSize: 13), decoration: const InputDecoration(hintText: 'Soni', isDense: true)))),
          const SizedBox(width: 6),
          Expanded(child: SizedBox(height: 38, child: TextField(controller: cc, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(fontSize: 13), decoration: const InputDecoration(hintText: 'Yangi tannarx', isDense: true)))),
        ]),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton(
            onPressed: () async {
              final sq = parseAmount(qc.text);
              if (sq == null || sq <= 0) return _msg('Sotiladigan sonni kiriting.');
              if (sq > nd(q['qty'])) return _msg('Omborda faqat ${q['qty']} ta bor.');
              final sa = fixAmt(sq * nd(q['price'])), sc = fixAmt(sq * nd(q['cost']));
              if (!(sa > 0)) return _msg("Narx noto'g'ri.");
              q['qty'] = r2(nd(q['qty']) - sq);
              q['sold'] = r2(nd(q['sold']) + sq);
              q['profit'] = fixAmt(nd(q['profit']) + sa - sc);
              final nn = 'Sotuv: ${q['name']} ×$sq';
              await _addTx(Tx(id: newId(), t: 'in', a: sa, c: 'b_sale', n: nn.length > 60 ? nn.substring(0, 60) : nn, d: todayStr(), ts: DateTime.now().millisecondsSinceEpoch, ex: {'e': c['id'], 'cg': sc}));
              qc.clear();
              await _done('Sotildi: +${grp(sa)} ${curUnit()}');
            },
            child: const Text('Sotish', style: TextStyle(color: kGold2, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () async {
              final bq = parseAmount(qc.text);
              final bc = cc.text.trim().isEmpty ? nd(q['cost']) : parseAmount(cc.text);
              if (bq == null || bq <= 0) return _msg('Xarid sonini kiriting.');
              if (bc == null || bc < 0) return _msg("Tannarxni to'g'ri kiriting.");
              final ba = fixAmt(bq * bc);
              if (!(ba > 0)) return _msg("Tannarx 0 bo'lmasin.");
              q['cost'] = r2((nd(q['qty']) * nd(q['cost']) + bq * bc) / (nd(q['qty']) + bq));
              q['qty'] = r2(nd(q['qty']) + bq);
              final nn = 'Xarid: ${q['name']} ×$bq';
              await _addTx(Tx(id: newId(), t: 'out', a: ba, c: 'b_stock', n: nn.length > 60 ? nn.substring(0, 60) : nn, d: todayStr(), ts: DateTime.now().millisecondsSinceEpoch, ex: {'e': c['id']}));
              qc.clear();
              cc.clear();
              await _done('Xarid yozildi: −${grp(ba)} ${curUnit()}');
            },
            child: const Text('Xarid', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          SureBtn(onSure: () {
            c['stock'] = eL(c, 'stock').where((y) => y['id'] != q['id']).toList();
            _done();
          }),
        ]),
      ]),
    );
  }

  /* ---------- PLAN ---------- */
  Widget _plan() {
    final cos = eVis();
    final s = eMon(mon);
    final pf = eProf(s);
    var pr = 0.0, pp = 0.0;
    for (final c in cos) {
      final x = eM(eM(c, 'plan'), mon);
      pr += nd(x['rev']);
      pp += nd(x['profit']);
    }
    final rp = pr > 0 ? (s.i / pr * 100).round() : null, fp = pp > 0 ? (pf / pp * 100).round() : null;
    final ks = <String>[];
    var m = mon;
    for (var i = 0; i < 6; i++) {
      ks.insert(0, m);
      m = prevMonthKey(m);
    }
    final pl = ks.map((k) => cos.fold<double>(0, (a, c) => a + nd(eM(eM(c, 'plan'), k)['rev']))).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _monRow(),
      _ek([
        ('Tushum rejasi', mny(pr), pr > 0 ? 'Fakt: ${mny(s.i)}' : 'Belgilanmagan', null),
        ('Tushum bajarilishi', rp == null ? '—' : '$rp%', "Reja bo'yicha", rp != null && rp >= 100 ? C.accent : null),
        ('Foyda rejasi', mny(pp), pp > 0 ? 'Fakt: ${sgn(pf)}' : 'Belgilanmagan', null),
        ('Foyda bajarilishi', fp == null ? '—' : '$fp%', "Reja bo'yicha", fp != null && fp >= 100 ? C.accent : null),
      ]),
      if (pr > 0 || pp > 0)
        uCard('Bajarilish', sub: mlab(mon), children: [
          if (pr > 0) _cb('Tushum', kGold, '${mny(s.i)} / ${mny(pr)}', math.min(100, s.i / pr * 100)),
          if (pp > 0) _cb('Foyda', kGold2, '${sgn(pf)} / ${mny(pp)}', math.max(0, math.min(100, pf / pp * 100))),
        ]),
      uCard('Reja va fakt', sub: 'tushum, 6 oy', children: [
        if (!pl.any((v) => v > 0)) uSmall("Reja belgilanmagan. Oylik maqsad kiriting.") else ...[
          _chart(EBarsPainter(ks.map((k) => kM3(int.parse(k.substring(5, 7)))).toList(), [('Reja', kGoldD, pl), ('Fakt', kGold2, ks.map((k) => eMon(k).i).toList())]), h: 220),
          _legend(const [('Reja', kGoldD), ('Fakt', kGold2)]),
        ],
      ]),
      for (final c in cos)
        Builder(builder: (_) {
          final id = '${c['id']}';
          final x = eM(eM(c, 'plan'), mon);
          final cs = eSum(app.listOf(mon).where((t) => t.ex['e'] == c['id']));
          final rc = ctl('pl-r-$id-$mon', nd(x['rev']) > 0 ? '${nd(x['rev']).round()}' : ''), pc = ctl('pl-p-$id-$mon', nd(x['profit']) > 0 ? '${nd(x['profit']).round()}' : '');
          return uCard('${c['name']}', sub: mlab(mon), children: [
            uSmall('Fakt: tushum ${mny(cs.i)}, foyda ${sgn(eProf(cs))}'),
            Row(children: [Expanded(child: uField(rc, 'Tushum maqsadi', num: true)), const SizedBox(width: 8), Expanded(child: uField(pc, 'Foyda maqsadi', num: true))]),
            const SizedBox(height: 10),
            _gold('Rejani saqlash', () {
              final rr = rc.text.trim().isEmpty ? 0.0 : parseAmount(rc.text), pq = pc.text.trim().isEmpty ? 0.0 : parseAmount(pc.text);
              if (rr == null || pq == null || rr < 0 || pq < 0) return _msg('Maqsadni raqam bilan kiriting.');
              eM(c, 'plan')[mon] = {'rev': rr, 'profit': pq};
              _done('Reja saqlandi');
            }),
          ]);
        }),
    ]);
  }

  /* ---------- INVOICES ---------- */
  Widget _inv() {
    final cos = eVis();
    final vt = double.tryParse(ctl('ev-vt').text.replaceAll(',', '.')) ?? 0;
    final dc = invCalc(draft, vt);
    if (idu.isEmpty) idu = dAdd(idt, 7);
    final il = <({Map<String, dynamic> v, Map<String, dynamic> c})>[];
    for (final c in cos) {
      for (final v in eL(c, 'inv')) {
        il.add((v: v, c: c));
      }
    }
    il.sort((a, b) {
      final x = '${b.v['date']}'.compareTo('${a.v['date']}');
      return x != 0 ? x : '${b.v['no']}'.compareTo('${a.v['no']}');
    });
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      uCard('Yangi hisob-faktura', children: [
        _coField('ev-co'),
        uField(ctl('ev-cl'), 'Mijoz nomi', max: 40),
        const SizedBox(height: 8),
        Row(children: [Expanded(child: _date(idt, (d) => setState(() => idt = d), hint: 'Sana')), const SizedBox(width: 8), Expanded(child: _date(idu, (d) => setState(() => idu = d), hint: "To'lov muddati"))]),
        const SizedBox(height: 8),
        uField(ctl('ev-vt'), 'QQS % (ixtiyoriy)', num: true, onChanged: (_) => setState(() {})),
        const SizedBox(height: 10),
        const Text('Qatorlar', style: TextStyle(color: C.dim, fontWeight: FontWeight.w700, fontSize: 12.5)),
        const SizedBox(height: 6),
        if (draft.isEmpty) uSmall("Hali qator yo'q."),
        for (var k = 0; k < draft.length; k++) URow(title: '${draft[k]['n']}', sub: '${draft[k]['q']} × ${mny(draft[k]['p'] as num)}', amount: mny((draft[k]['q'] as num) * (draft[k]['p'] as num)), action: IconButton(visualDensity: VisualDensity.compact, icon: const Icon(Icons.close_rounded, size: 18, color: C.out), onPressed: () => setState(() => draft.removeAt(k)))),
        if (draft.isNotEmpty) uSmall('Jami: ${mny(dc.sub)}${dc.vat > 0 ? ' + QQS ${mny(dc.vat)} = ${mny(dc.tot)}' : ''}'),
        uField(ctl('ev-in'), 'Mahsulot yoki xizmat nomi', max: 60),
        const SizedBox(height: 8),
        Row(children: [Expanded(child: uField(ctl('ev-iq', '1'), 'Soni', num: true)), const SizedBox(width: 8), Expanded(child: uField(ctl('ev-ip'), 'Narxi', num: true))]),
        const SizedBox(height: 10),
        _gold("Qatorni qo'shish", () {
          final nm = ctl('ev-in').text.trim();
          final q = parseAmount(ctl('ev-iq').text.trim().isEmpty ? '1' : ctl('ev-iq').text), pr = parseAmount(ctl('ev-ip').text);
          if (nm.length < 2) return _msg('Mahsulot yoki xizmat nomini kiriting.');
          if (q == null || q <= 0) return _msg('Sonini kiriting.');
          if (ctl('ev-ip').text.trim().isEmpty || pr == null || pr < 0) return _msg('Narxni kiriting.');
          if (draft.length >= 30) return _msg("Eng ko'pi 30 qator.");
          setState(() {
            draft.add({'n': nm, 'q': q, 'p': fixAmt(pr)});
            ctl('ev-in').clear();
            ctl('ev-ip').clear();
            ctl('ev-iq').text = '1';
          });
        }, ghost: true),
        const SizedBox(height: 8),
        _gold('Hisob-faktura yaratish', _createInv),
      ]),
      uCard('Hisob-fakturalar', sub: '${il.length} ta', children: [
        if (il.isEmpty) uSmall("Hali hisob-faktura yo'q."),
        for (final o in il) _invRow(o.v, o.c),
      ]),
    ]);
  }

  Future<void> _createInv() async {
    if (ctl('ev-in').text.trim().isNotEmpty && ctl('ev-ip').text.trim().isNotEmpty) {
      final q = parseAmount(ctl('ev-iq').text.trim().isEmpty ? '1' : ctl('ev-iq').text), pr = parseAmount(ctl('ev-ip').text);
      if (q != null && q > 0 && pr != null && pr >= 0 && ctl('ev-in').text.trim().length >= 2) {
        draft.add({'n': ctl('ev-in').text.trim(), 'q': q, 'p': fixAmt(pr)});
        ctl('ev-in').clear();
        ctl('ev-ip').clear();
      }
    }
    final c3 = eCo(_coId('ev-co'));
    final cl = ctl('ev-cl').text.trim();
    final vt = ctl('ev-vt').text.trim().isEmpty ? 0.0 : (double.tryParse(ctl('ev-vt').text.trim().replaceAll(',', '.')) ?? -1);
    if (c3 == null) return _msg('Kompaniyani tanlang.');
    if (cl.length < 2) return _msg('Mijoz nomini kiriting.');
    if (draft.isEmpty) return _msg("Kamida bitta qator qo'shing.");
    if (idu.isNotEmpty && idu.compareTo(idt) < 0) return _msg("To'lov muddati sanadan oldin bo'lmasin.");
    if (!(vt >= 0 && vt <= 100)) return _msg("QQS 0 dan 100 gacha bo'lsin.");
    var mxn = 0;
    for (final y in eL(c3, 'inv')) {
      final k = int.tryParse('${y['no']}'.length > 4 ? '${y['no']}'.substring(4) : '') ?? 0;
      if (k > mxn) mxn = k;
    }
    final ct = invCalc(draft, vt);
    eL(c3, 'inv').add({'id': nid(), 'no': 'INV-${(mxn + 1).toString().padLeft(4, '0')}', 'client': cl, 'date': idt, 'due': idu, 'items': draft.map((e) => Map<String, dynamic>.from(e)).toList(), 'vat': vt, 'total': ct.tot, 'paid': 0, 'paidAt': ''});
    draft.clear();
    ctl('ev-cl').clear();
    ctl('ev-vt').clear();
    idt = todayStr();
    idu = '';
    await _done('Hisob-faktura yaratildi');
  }

  Widget _invRow(Map<String, dynamic> v, Map<String, dynamic> c) {
    final st = invSt(v);
    final total = nd(v['total']), paid = nd(v['paid']);
    final qd = fixAmt(total - paid);
    final id = '${v['id']}';
    final pc = ctl('ev-p-$id');
    final due = '${v['due'] ?? ''}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: const Color(0x08FFFFFF), border: Border.all(color: st == 'late' ? C.out.withOpacity(.4) : C.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${v['no']} · ${v['client']}', style: const TextStyle(fontWeight: FontWeight.w700)),
            Text.rich(TextSpan(style: const TextStyle(color: C.dim, fontSize: 12.5), children: [TextSpan(text: '${v['date']}${due.isNotEmpty ? ' · muddati $due' : ''}${eTag(c)} · '), TextSpan(text: kInvL[st], style: TextStyle(color: st == 'paid' ? C.accent : st == 'late' ? C.out : C.dim)), if (paid > 0 && st != 'paid') TextSpan(text: " · to'langan ${mny(paid)}")])),
          ])),
          Text(mny(total), style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          if (st != 'paid') ...[
            Expanded(child: SizedBox(height: 38, child: TextField(controller: pc, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(fontSize: 13), decoration: InputDecoration(hintText: 'Summa (${mny(qd)})', isDense: true)))),
            TextButton(
              onPressed: () async {
                final am = pc.text.trim().isEmpty ? qd : parseAmount(pc.text);
                if (am == null || am <= 0) return _msg("Summani to'g'ri kiriting.");
                if (am > qd + .001) return _msg('Summa qarzdan oshmasin: ${mny(qd)}');
                final ta = fixAmt(am);
                final nn = 'Hisob-faktura ${v['no']} · ${v['client']}';
                await _addTx(Tx(id: newId(), t: 'in', a: ta, c: 'b_sale', n: nn.length > 60 ? nn.substring(0, 60) : nn, d: todayStr(), ts: DateTime.now().millisecondsSinceEpoch, ex: {'e': c['id']}));
                var np = r2(paid + ta);
                if (np > total) np = total;
                v['paid'] = np;
                v['paidAt'] = todayStr();
                pc.clear();
                await _done("To'lov qabul qilindi: +${grp(ta)} ${curUnit()}");
              },
              child: const Text("To'lov qabul qilish", style: TextStyle(color: kGold2, fontWeight: FontWeight.w700, fontSize: 12.5)),
            ),
          ] else
            const Spacer(),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _invTxt(v, c)));
              if (mounted) _msg('Nusxalandi');
            },
            child: const Text('Nusxa', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
          ),
          SureBtn(onSure: () {
            c['inv'] = eL(c, 'inv').where((y) => y['id'] != v['id']).toList();
            _done("O'chirildi");
          }),
        ]),
      ]),
    );
  }

  String _invTxt(Map<String, dynamic> v, Map<String, dynamic> c) {
    final cc = invCalc(v['items'] as List, nd(v['vat']));
    final b = StringBuffer('Hisob-faktura № ${v['no']}\nSana: ${v['date']}${'${v['due'] ?? ''}'.isNotEmpty ? " · To'lov muddati: ${v['due']}" : ''}\n');
    b.writeln("Sotuvchi: ${c['name']}${'${c['inn'] ?? ''}'.isNotEmpty ? ' · STIR: ${c['inn']}' : ''}${'${c['phone'] ?? ''}'.isNotEmpty ? ' · Tel: ${c['phone']}' : ''}");
    b.writeln('Xaridor: ${v['client']}\n');
    for (final it in v['items'] as List) {
      b.writeln('${it['n']}: ${it['q']} × ${mny(it['p'] as num)} = ${mny((it['q'] as num) * (it['p'] as num))}');
    }
    b.writeln('\nJami: ${mny(cc.sub)}');
    if (nd(v['vat']) > 0) b.writeln('QQS (${v['vat']}%): ${mny(cc.vat)}');
    b.writeln("To'lanishi kerak: ${mny(cc.tot)}");
    if (nd(v['paid']) > 0) b.writeln("To'langan: ${mny(nd(v['paid']))}\nQoldiq: ${mny(math.max(0, cc.tot - nd(v['paid'])))}");
    if ('${c['req'] ?? ''}'.isNotEmpty) b.writeln("\nTo'lov rekvizitlari: ${c['req']}");
    return b.toString();
  }

  /* ---------- OPERATIONS ---------- */
  Widget _tx() {
    final set = eVset();
    final l = app.txs.where((x) => x.ex['e'] != null && set.contains('${x.ex['e']}')).toList()..sort((a, b) => a.d == b.d ? b.ts.compareTo(a.ts) : b.d.compareTo(a.d));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      uCard('Yangi operatsiya', children: _txForm()),
      uCard('Oxirgi operatsiyalar', children: [
        if (l.isEmpty) uSmall("Hali operatsiya yo'q."),
        for (final x in l.take(30))
          Builder(builder: (_) {
            final c = catOf(x.t, x.c), co = eCo('${x.ex['e']}');
            return URow(title: c.name, sub: '${x.d}${x.n.isNotEmpty ? ' · ${x.n}' : ''}${co != null ? eTag(co) : ''}', amount: '${x.t == 'in' ? '+' : '−'}${mny(x.a)}', amountColor: x.t == 'in' ? C.accent : C.out, action: SureBtn(onSure: () async {
              await app.removeTx(x.id);
              if (mounted) {
                setState(() {});
                _msg("Operatsiya o'chirildi");
              }
            }));
          }),
      ]),
    ]);
  }

  /* ---------- REPORT ---------- */
  Widget _rep() {
    final s = eMon(mon);
    final pf = eProf(s), cg = eStockCost(s), opx = s.o - (s.bo['b_stock'] ?? 0), tax = eTaxSum(mon);
    final mg = s.i > 0 ? (pf / s.i * 100).round() : null;
    final cats = s.bo.keys.toList()..sort((a, b) => s.bo[b]!.compareTo(s.bo[a]!));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _monRow(),
      uCard('Foyda va zarar', sub: mlab(mon), children: [
        URow(title: 'Tushum', amount: mny(s.i)),
        URow(title: 'Tovar tannarxi', sub: s.cg > 0 ? 'Sotilgan tovar tannarxi' : 'Tovar xaridi', amount: '−${mny(cg)}'),
        URow(title: 'Operatsion xarajatlar', amount: '−${mny(opx)}'),
        URow(title: 'Foyda', sub: mg == null ? "Tushum yo'q" : 'Marja $mg%', amount: sgn(pf), amountColor: pf < 0 ? C.out : C.accent),
        if (tax > 0) ...[URow(title: 'Taxminiy soliq', sub: "Kompaniya stavkalari bo'yicha", amount: '−${mny(tax)}'), URow(title: 'Soliqdan keyingi foyda', amount: sgn(pf - tax))],
      ]),
      uCard('Xarajat tuzilmasi', children: [
        if (cats.isEmpty) uSmall("Bu oyda xarajat yo'q."),
        for (final k in cats) _cb(catOf('out', k).name, catOf('out', k).color, '${mny(s.bo[k]!)} · ${(s.bo[k]! / s.o * 100).round()}%', s.bo[k]! / s.o * 100),
      ]),
      uCard('Rahbar hisoboti', children: [
        uSmall("Hamkor yoki bankka ko'rsatishga tayyor oylik hisobot: ko'rsatkichlar, foyda/zarar, qarzdorlik yoshi, kassa prognozi, reja-fakt, xodimlar va ombor. (Matn ko'rinishida nusxalanadi.)"),
        _gold('Rahbar hisobotini nusxalash', () async {
          await Clipboard.setData(ClipboardData(text: eRepText(mon)));
          if (mounted) _msg('Hisobot nusxalandi');
        }),
        const SizedBox(height: 8),
        _gold('Operatsiyalarni CSV nusxalash', () async {
          final set = eVset();
          final list = app.txs.where((y) => y.ex['e'] != null && set.contains('${y.ex['e']}')).toList();
          if (list.isEmpty) return _msg("Yuklash uchun operatsiya yo'q");
          String q(String s) => RegExp(r'[",\n;]').hasMatch(s) ? '"${s.replaceAll('"', '""')}"' : s;
          final rows = <List<String>>[
            ['Sana', 'Kompaniya', 'Turi', 'Kategoriya', 'Izoh', 'Summa', 'Valyuta']
          ];
          list.sort((m, n) => m.d == n.d ? m.ts.compareTo(n.ts) : m.d.compareTo(n.d));
          for (final y in list) {
            final k = eCo('${y.ex['e']}');
            rows.add([y.d, k != null ? '${k['name']}' : '', y.t == 'in' ? 'Kirim' : 'Chiqim', catOf(y.t, y.c).name, y.n, '${y.a}', app.cur]);
          }
          await Clipboard.setData(ClipboardData(text: rows.map((r) => r.map(q).join(',')).join('\r\n')));
          if (mounted) _msg('CSV nusxalandi');
        }, ghost: true),
      ]),
    ]);
  }

  /* ---------- COMPANIES ---------- */
  Widget _co() {
    final E = eInit();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      uCard('Yangi kompaniya', children: [
        uField(ctl('k-new'), 'Kompaniya nomi', max: 40),
        const SizedBox(height: 10),
        _gold("Qo'shish", _addCo),
        uSmall("Har bir kompaniya alohida hisob yuritadi, «Umumiy ko'rinish» hammasini jamlaydi. Eng ko'pi 10 ta."),
      ]),
      for (final c in eVis()) _coCard(E, c),
    ]);
  }

  Widget _coCard(Map<String, dynamic> E, Map<String, dynamic> c) {
    final I = '${c['id']}';
    final tl = eL(c, 'tl');
    String nz(double v) => v != 0 ? '${v % 1 == 0 ? v.toInt() : v}' : '';
    final tkv = _sel['t-k-$I'] ?? 'm';
    return uCard('${c['name']}', children: [
      uField(ctl('k-n-$I', '${c['name']}'), 'Nomi', max: 40),
      const SizedBox(height: 8),
      Row(children: [Expanded(child: uField(ctl('k-i-$I', '${c['inn'] ?? ''}'), 'STIR', max: 20)), const SizedBox(width: 8), Expanded(child: uField(ctl('k-p-$I', '${c['phone'] ?? ''}'), 'Telefon', max: 20))]),
      const SizedBox(height: 8),
      uField(ctl('k-r-$I', '${c['req'] ?? ''}'), "To'lov rekvizitlari", max: 120),
      const SizedBox(height: 8),
      Row(children: [Expanded(child: uField(ctl('k-t-$I', nz(nd(c['tax']))), 'Soliq stavkasi, %', num: true)), const SizedBox(width: 8), Expanded(child: uField(ctl('k-c-$I', nz(nd(c['cash']))), "Boshlang'ich kassa", num: true))]),
      const SizedBox(height: 8),
      uField(ctl('k-f-$I', nz(nd(c['fixed']))), "Qo'shimcha doimiy xarajat (oyiga)", num: true),
      uSmall("Prognoz va zararsizlik hisobiga qo'shiladi (masalan, internet, obuna)."),
      _gold('Saqlash', () {
        final n2 = ctl('k-n-$I').text.trim();
        final tr = ctl('k-t-$I').text.trim().isEmpty ? 0.0 : parseAmount(ctl('k-t-$I').text);
        final cs = ctl('k-c-$I').text.trim().isEmpty ? 0.0 : parseAmount(ctl('k-c-$I').text);
        final fx = ctl('k-f-$I').text.trim().isEmpty ? 0.0 : parseAmount(ctl('k-f-$I').text);
        if (n2.length < 2) return _msg('Nomini kiriting.');
        if (tr == null || tr < 0 || tr > 100) return _msg("Stavka 0 dan 100 gacha bo'lsin.");
        if (cs == null) return _msg("Kassa qoldig'ini raqam bilan kiriting.");
        if (fx == null || fx < 0) return _msg('Xarajatni raqam bilan kiriting.');
        c['name'] = n2;
        c['inn'] = ctl('k-i-$I').text.trim();
        c['phone'] = ctl('k-p-$I').text.trim();
        c['req'] = ctl('k-r-$I').text.trim();
        c['tax'] = tr;
        c['cash'] = cs;
        c['fixed'] = fx;
        _done('Saqlandi');
      }),
      const SizedBox(height: 16),
      const Text("Soliq va to'lov muddatlari", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      const SizedBox(height: 8),
      if (tl.isEmpty) uSmall("Muddatlar yo'q. 3 kun oldin eslatamiz."),
      for (final x in tl)
        Builder(builder: (_) {
          final m = x['kind'] == 'm';
          final d = m ? daysTo(nd(x['day']).toInt()) : dueIn('${x['date']}');
          return URow(title: '${x['name']}', sub: '${m ? 'Har oy ${x['day']}-kuni' : x['date']} · ${d < 0 ? "muddati o'tgan" : d > 0 ? '$d kun qoldi' : 'bugun'}', amount: nd(x['amt']) > 0 ? mny(nd(x['amt'])) : '', late: d <= 3, action: SureBtn(onSure: () {
            c['tl'] = tl.where((y) => y['id'] != x['id']).toList();
            _done();
          }));
        }),
      uField(ctl('t-n-$I'), "Nomi (Soliq to'lovi)", max: 40),
      const SizedBox(height: 8),
      Row(children: [Expanded(child: _dd<String>(tkv, const [('m', 'Har oy'), ('o', 'Bir marta')], (v) => setState(() => _sel['t-k-$I'] = v))), const SizedBox(width: 8), Expanded(child: uField(ctl('t-a-$I'), 'Summa (ixtiyoriy)', num: true))]),
      const SizedBox(height: 8),
      if (tkv == 'm') uField(ctl('t-d-$I'), 'Oyning kuni (1-31)', kt: TextInputType.number) else _date(_sel['t-dt-$I'] ?? '', (d) => setState(() => _sel['t-dt-$I'] = d), hint: 'Sanani tanlang'),
      const SizedBox(height: 10),
      _gold("Muddat qo'shish", () {
        final tn = ctl('t-n-$I').text.trim();
        final ta = ctl('t-a-$I').text.trim().isEmpty ? 0.0 : parseAmount(ctl('t-a-$I').text);
        final dy = parseAmount(ctl('t-d-$I').text)?.round();
        final dt = _sel['t-dt-$I'] ?? '';
        if (tn.length < 2) return _msg('Nomini kiriting.');
        if (ta == null || ta < 0) return _msg('Summani raqam bilan kiriting.');
        if (tkv == 'm' && (dy == null || dy < 1 || dy > 31)) return _msg("Kun 1 dan 31 gacha bo'lsin.");
        if (tkv == 'o' && dt.isEmpty) return _msg('Sanani kiriting.');
        tl.add({'id': nid(), 'name': tn, 'kind': tkv, 'day': dy ?? 0, 'date': dt, 'amt': ta});
        ctl('t-n-$I').clear();
        ctl('t-a-$I').clear();
        ctl('t-d-$I').clear();
        _sel.remove('t-dt-$I');
        _done("Qo'shildi");
      }, ghost: true),
      const SizedBox(height: 10),
      Align(
        alignment: Alignment.centerRight,
        child: SureBtn(label: "Kompaniyani o'chirish", onSure: () async {
          final ids = app.txs.where((x) => x.ex['e'] == c['id']).map((x) => x.id).toList();
          for (final id in ids) {
            await app.removeTx(id);
          }
          final cos = eL(E, 'cos');
          E['cos'] = cos.where((y) => y['id'] != c['id']).toList();
          if (E['act'] == c['id']) E['act'] = 'all';
          await _done("Kompaniya o'chirildi");
        }),
      ),
    ]);
  }
}

/* ====================================================================== */
/*  VAULT EMPIRE (Business): 3D business control centre                    */
/* ====================================================================== */
class _EmZ {
  final String k, n, t;
  final List<String> cats;
  final List<double> col;
  const _EmZ(this.k, this.n, this.t, this.cats, this.col);
}

const List<_EmZ> kEZ = [
  _EmZ('sale', 'Savdo', 'in', [], [205, 216, 232]),
  _EmZ('stock', 'Ombor va xarid', 'out', ['b_stock'], [110, 170, 220]),
  _EmZ('pay', 'Kadrlar', 'out', ['b_pay'], [214, 140, 186]),
  _EmZ('ads', 'Marketing', 'out', ['b_ads'], [236, 164, 98]),
  _EmZ('rent', 'Ofis va ijara', 'out', ['b_rent'], [160, 140, 226]),
  _EmZ('tax', 'Soliq va moliya', 'out', ['b_tax'], [150, 168, 190]),
  _EmZ('oth', 'Boshqa', 'out', [], [140, 150, 166]),
];
const double kEZR = 330;
final List<({double x, double z, double a})> kEZP = [
  for (var i = 0; i < kEZ.length; i++)
    (
      x: (kEZR * math.cos(-math.pi / 2 + i * 2 * math.pi / kEZ.length)).roundToDouble(),
      z: (kEZR * math.sin(-math.pi / 2 + i * 2 * math.pi / kEZ.length)).roundToDouble(),
      a: -math.pi / 2 + i * 2 * math.pi / kEZ.length
    )
];
const List<List<double>> kEmLC = [[150, 225, 255], [255, 196, 90], [255, 90, 80]];
const List<double> kEmSH = [.9, .38, .34, 1];

Color _emC(List<double> t, double m, double a) => Color.fromRGBO(math.min(255, (t[0] * m).round()), math.min(255, (t[1] * m).round()), math.min(255, (t[2] * m).round()), a.clamp(0.0, 1.0));
Color _emRgb(List<double> t, double a) => Color.fromRGBO(t[0].round(), t[1].round(), t[2].round(), a.clamp(0.0, 1.0));
List<double> _emMix(List<double> a, List<double> b, double t) => [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t];
double _emH(double n) {
  final x = math.sin(n * 127.1) * 43758.5453;
  return x - x.floorToDouble();
}

String _emZk(String c) {
  for (var i = 1; i < kEZ.length - 1; i++) {
    if (kEZ[i].cats.contains(c)) return kEZ[i].k;
  }
  return 'oth';
}

class _EmM {
  String mk;
  double i = 0, o = 0, p = 0;
  int n = 0;
  final Map<String, double> z = {for (final e in kEZ) e.k: 0.0};
  final Map<String, double> cc = {};
  _EmM(this.mk);
}

class _EmCtx {
  Map<String, double> lim = {};
  double bud = 0, od = 0, pend = 0;
  int on = 0;
  List<({String n, int d})> tax = [];
  bool now = true;
}

class _EmRisk {
  final int l;
  final String t, d, z;
  _EmRisk(this.l, this.t, this.d, [this.z = '']);
}

class _EmPart {
  final int i;
  double t = 0;
  final double sp, j;
  _EmPart(this.i, this.sp, this.j);
}

class _EmHit {
  final int i;
  final double x, y, r;
  _EmHit(this.i, this.x, this.y, this.r);
}

class _EmStar {
  final double x, y, d, tw;
  _EmStar(this.x, this.y, this.d, this.tw);
}

class _EmS {
  double t = 0, intro = 0, ib = 0, yaw = .62, pitch = .52, uz = 1, zoom = 1, fx = 0, fy = 150, fz = 0, w = 0, h = 0, sc = 1, vel = 0, spawn = 0, chk = 0, playT = 0;
  int sel = -1, idx = 0, lvl = 0, score = 100;
  String mk = '', sig = '';
  bool demo = false, empty = false, play = false, film = false;
  Map<String, double> dp = {}, tg = {};
  List<String> ks = [];
  List<_EmM> ser = [];
  _EmM? m, pm;
  _EmCtx ctx = _EmCtx();
  List<_EmRisk> R = [];
  Map<String, int> zl = {};
  List<_EmPart> parts = [];
  List<_EmHit> scr = [];
  Map<int, Offset> lab = {};
  ({double x, double y, double k})? tow;
  List<_EmStar> stars = [];
}

/* ---- data ---- */
_EmM _emReal(String mk) {
  final o = _EmM(mk);
  for (final x in app.listOf(mk)) {
    if (x.ex['b'] == null) continue;
    o.n++;
    if (x.t == 'in') {
      o.i += x.a;
      o.z['sale'] = o.z['sale']! + x.a;
    } else {
      o.o += x.a;
      final k = _emZk(x.c);
      o.z[k] = o.z[k]! + x.a;
      o.cc[x.c] = (o.cc[x.c] ?? 0) + x.a;
    }
  }
  o.p = o.i - o.o;
  return o;
}

double _emFx() => app.cur == 'UZS' ? 1.0 : ((kCurd[app.cur]?[1] as num?)?.toDouble() ?? 12000) / 12000.0;

_EmM _emDemo(String mk) {
  final p = mk.split('-'), mi = int.parse(p[0]) * 12 + (int.parse(p[1]) - 1);
  final b = monthKeyOf(DateTime.now()).split('-'), age = (int.parse(b[0]) * 12 + (int.parse(b[1]) - 1)) - mi;
  final f = _emFx();
  double r(double s) {
    final x = math.sin(mi * 12.9898 + s * 78.233) * 43758.5453;
    return x - x.floorToDouble();
  }

  final g = 1 - age * .03, rev0 = 58e6 * g;
  var rev = rev0 * (.86 + r(1) * .28);
  if (age == 4) rev *= .68;
  final sh = {'stock': .34 + r(2) * .05, 'pay': .19 + r(3) * .02, 'ads': .055 + r(4) * .02, 'rent': .07, 'tax': .045 + r(5) * .01, 'oth': .03 + r(6) * .015};
  if (age == 0) {
    sh['ads'] = .115;
    rev *= .97;
  }
  final o = _EmM(mk);
  o.i = (rev * f).roundToDouble();
  o.n = (22 + r(7) * 20).round();
  o.z['sale'] = o.i;
  for (final k in ['stock', 'pay', 'ads', 'rent', 'tax', 'oth']) {
    final v = (rev0 * sh[k]! * f).roundToDouble();
    o.z[k] = v;
    o.o += v;
  }
  o.cc.addAll({'b_stock': o.z['stock']!, 'b_pay': o.z['pay']!, 'b_ads': o.z['ads']!, 'b_rent': o.z['rent']!, 'b_tax': o.z['tax']!});
  o.p = o.i - o.o;
  return o;
}

_EmM _emMon(_EmS s, String mk) => s.demo ? _emDemo(mk) : _emReal(mk);

_EmCtx _emCtx(_EmS s) {
  final x = _EmCtx(), f = _emFx();
  if (s.demo) {
    x.lim = {'b_ads': (5e6 * f).roundToDouble()};
    x.bud = (46e6 * f).roundToDouble();
    x.od = (9.4e6 * f).roundToDouble();
    x.on = 2;
    x.pend = (21e6 * f).roundToDouble();
    x.tax = [(n: "QQS to'lovi", d: 2)];
    return x;
  }
  final p = app.profile!;
  for (final v in p.lst('inv')) {
    final d = ((v['total'] ?? 0) as num).toDouble() - ((v['paid'] ?? 0) as num).toDouble();
    if (d > .001) {
      x.pend += d;
      if (invSt(v) == 'late') {
        x.od += d;
        x.on++;
      }
    }
  }
  for (final t in p.lst('bizTax')) {
    final d = t['kind'] == 'm' ? daysTo(((t['day'] ?? 1) as num).toInt()) : dueIn('${t['date'] ?? ''}');
    if (d <= 7) x.tax.add((n: '${t['name']}', d: d));
  }
  final cl = p.mp('catLimits');
  cl.forEach((k, v) => x.lim[k] = (v as num).toDouble());
  x.bud = ((p.mp('biz')['budget'] ?? 0) as num).toDouble();
  return x;
}

List<_EmRisk> _emRisks(_EmM m, _EmM pm, _EmCtx x) {
  final R = <_EmRisk>[];
  int pc(double a, double b) => b > 0 ? (a / b * 100).round() : 0;
  if (m.o > m.i && m.o > 0) {
    R.add(_EmRisk(2, 'Zarar: xarajat tushumdan oshgan', 'Farq −${mny(m.o - m.i)}${m.i > 0 ? ' · xarajat tushumning ${pc(m.o, m.i)}% i' : ''}'));
  } else if (m.i > 0 && m.p / m.i < .1) {
    R.add(_EmRisk(1, 'Foyda marjasi past', 'Marja ${(m.p / m.i * 100).round()}%, tavsiya: 10% dan yuqori'));
  }
  if (pm.o > 0 && m.o > pm.o * 1.3) R.add(_EmRisk(1, 'Xarajat keskin oshgan', "+${((m.o / pm.o - 1) * 100).round()}% o'tgan oyga nisbatan"));
  for (final z in kEZ) {
    for (final c in z.cats) {
      final lim = x.lim[c] ?? 0, v = m.cc[c] ?? 0;
      if (lim > 0) {
        if (v > lim) {
          R.add(_EmRisk(2, '${z.n}: limitdan oshgan', '${mny(v)} / ${mny(lim)}', z.k));
        } else if (v >= lim * .8) {
          R.add(_EmRisk(1, '${z.n}: limitning 80% i sarflandi', '${mny(v)} / ${mny(lim)}', z.k));
        }
      }
    }
  }
  if (x.bud > 0) {
    if (m.o > x.bud) {
      R.add(_EmRisk(2, 'Oylik byudjetdan oshgan', '${mny(m.o)} / ${mny(x.bud)}'));
    } else if (m.o >= x.bud * .85) {
      R.add(_EmRisk(1, "Byudjetning 85% i sarflandi", '${mny(m.o)} / ${mny(x.bud)}'));
    }
  }
  if (x.now) {
    if (x.on > 0) R.add(_EmRisk(x.on > 2 || (m.i > 0 && x.od > m.i * .3) ? 2 : 1, "Kechikkan to'lovlar", "${x.on} ta hisob-faktura · ${mny(x.od)}", 'sale'));
    for (final t in x.tax) {
      if (t.d < 0) {
        R.add(_EmRisk(2, "${t.n}: muddati o'tgan", '${-t.d} kun kechikkan', 'tax'));
      } else if (t.d <= 3) {
        R.add(_EmRisk(t.d <= 1 ? 2 : 1, '${t.n}: muddat yaqin', t.d > 0 ? '${t.d} kun qoldi' : 'bugun', 'tax'));
      }
    }
  }
  R.sort((a, b) => b.l.compareTo(a.l));
  return R;
}

/* ---- painter ---- */
typedef _P3 = List<double>; // [x, y, k, z]

class _EmPainter extends CustomPainter {
  final _EmS s;
  _EmPainter(this.s, Listenable l) : super(repaint: l);

  late Canvas c;
  late double T;

  _P3 P(double x, double y, double z) {
    x -= s.fx;
    y -= s.fy;
    z -= s.fz;
    final yw = s.yaw + (1 - s.ib) * 2.2, cy = math.cos(yw), sn = math.sin(yw), cp = math.cos(s.pitch), sp = math.sin(s.pitch);
    final x1 = x * cy - z * sn, z1 = x * sn + z * cy, y2 = y * cp + z1 * sp, z2 = z1 * cp - y * sp, k = 1100 / (1100 + z2) * s.sc;
    return [s.w / 2 + x1 * k, s.h * .56 - y2 * k, k, z2];
  }

  ({List<_P3> b, List<_P3> t}) box(double cx, double cz, double hw, double y0, double y1) {
    const xs = [-1, 1, 1, -1], zs = [-1, -1, 1, 1];
    final b = <_P3>[], t = <_P3>[];
    for (var i = 0; i < 4; i++) {
      b.add(P(cx + xs[i] * hw, y0, cz + zs[i] * hw));
      t.add(P(cx + xs[i] * hw, y1, cz + zs[i] * hw));
    }
    return (b: b, t: t);
  }

  List<_P3>? face(({List<_P3> b, List<_P3> t}) bx, int f, List<double> tint, double al, double br) {
    final b = (f + 1) % 4, A = bx.b[f], B = bx.b[b], C = bx.t[b], D = bx.t[f];
    if ((A[0] * B[1] - B[0] * A[1]) + (B[0] * C[1] - C[0] * B[1]) + (C[0] * D[1] - D[0] * C[1]) + (D[0] * A[1] - A[0] * D[1]) >= 0) return null;
    final sh = kEmSH[f] * br;
    final y0 = math.min(C[1], D[1]), y1 = math.max(A[1], B[1]) + 1;
    final path = Path()..addPolygon([Offset(A[0], A[1]), Offset(B[0], B[1]), Offset(C[0], C[1]), Offset(D[0], D[1])], true);
    c.drawPath(path, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_emC(tint, sh * 1.2, al), _emC(tint, sh * .68, al)]).createShader(Rect.fromLTRB(0, y0, 1, math.max(y1, y0 + 1))));
    c.drawPath(path, Paint()..color = const Color(0x4DD6E0F0)..style = PaintingStyle.stroke..strokeWidth = 1);
    return [A, B, C, D];
  }

  void top(({List<_P3> b, List<_P3> t}) bx, List<double> tint, double al, double br) {
    final t = bx.t;
    final path = Path()..addPolygon([for (final q in t) Offset(q[0], q[1])], true);
    c.drawPath(path, Paint()..color = _emC(tint, 1.25 * br, al));
    c.drawPath(path, Paint()..color = const Color(0x80E6EEFA)..style = PaintingStyle.stroke..strokeWidth = 1);
  }

  void wins(List<_P3> q, int nc, double lit, int seed, Color litCol) {
    final A = q[0], B = q[1], C = q[2], D = q[3];
    final L = <List<double>>[], U = <List<double>>[];
    for (var i = 0; i < nc; i++) {
      final h = _emH((seed + i * 17).toDouble());
      var on = h < lit;
      if ((h - lit).abs() < .06) on = math.sin(T * 1.7 + h * 40) > 0;
      (on ? L : U).add([(i + .2) / nc, (i + .8) / nc]);
    }
    Path mk(List<List<double>> arr) {
      final path = Path();
      for (final w in arr) {
        final pts = <Offset>[];
        for (final p in [[w[0], .22], [w[1], .22], [w[1], .78], [w[0], .78]]) {
          final u = p[0], v = p[1];
          final bx = A[0] + (B[0] - A[0]) * u, by = A[1] + (B[1] - A[1]) * u, tx = D[0] + (C[0] - D[0]) * u, ty = D[1] + (C[1] - D[1]) * u;
          pts.add(Offset(bx + (tx - bx) * v, by + (ty - by) * v));
        }
        path.addPolygon(pts, true);
      }
      return path;
    }

    c.drawPath(mk(U), Paint()..color = const Color(0x8C080C16));
    c.drawPath(mk(L), Paint()..color = litCol);
  }

  void crack(List<_P3> q, int seed) {
    final A = q[0], B = q[1], C = q[2], D = q[3];
    var u = .25 + _emH(seed.toDouble()) * .5;
    Offset uv(double u, double v) {
      final bx = A[0] + (B[0] - A[0]) * u, by = A[1] + (B[1] - A[1]) * u, tx = D[0] + (C[0] - D[0]) * u, ty = D[1] + (C[1] - D[1]) * u;
      return Offset(bx + (tx - bx) * v, by + (ty - by) * v);
    }

    final path = Path();
    var p = uv(u, 0);
    path.moveTo(p.dx, p.dy);
    for (var k = 1; k <= 4; k++) {
      u = math.max(.08, math.min(.92, u + (_emH((seed + k * 5).toDouble()) - .5) * .35));
      p = uv(u, k * .25);
      path.lineTo(p.dx, p.dy);
    }
    c.drawPath(path, Paint()..color = const Color(0xD9FF785F)..style = PaintingStyle.stroke..strokeWidth = 1.3);
  }

  void halo(double x, double y, double r, List<double> rgb, double a, {bool add = false}) {
    if (r <= 0) return;
    c.drawCircle(Offset(x, y), r, Paint()..blendMode = add ? BlendMode.plus : BlendMode.srcOver..shader = RadialGradient(colors: [_emRgb(rgb, a), _emRgb(rgb, 0)]).createShader(Rect.fromCircle(center: Offset(x, y), radius: r)));
  }

  List<_P3> ringPts(double cx, double cz, double r, double y, int n) => [for (var i = 0; i < n; i++) P(cx + r * math.cos(i / n * 6.2832), y, cz + r * math.sin(i / n * 6.2832))];

  void ring(double cx, double cz, double r, double y, List<double> rgb, double al, double w, {bool dash = false}) {
    final pts = ringPts(cx, cz, r, y, 56);
    final path = Path()..addPolygon([for (final q in pts) Offset(q[0], q[1])], true);
    if (dash) {
      final dp = Path();
      for (final m in path.computeMetrics()) {
        var d = (-T * 30) % 16;
        while (d < m.length) {
          dp.addPath(m.extractPath(d, math.min(m.length, d + 8)), Offset.zero);
          d += 16;
        }
      }
      c.drawPath(dp, Paint()..color = _emRgb(rgb, al)..style = PaintingStyle.stroke..strokeWidth = w);
    } else {
      c.drawPath(path, Paint()..color = _emRgb(rgb, al)..style = PaintingStyle.stroke..strokeWidth = w);
    }
  }

  double hw(double fr) => fr < .42 ? 74 : fr < .74 ? 60 : 46;

  void ground() {
    const R = 520.0;
    final c0 = P(0, 0, 0), lo = ringPts(0, 0, R, -18, 72), hi = ringPts(0, 0, R, 0, 72);
    final pl = Path()..addPolygon([for (final q in lo) Offset(q[0], q[1])], true);
    c.drawPath(pl, Paint()..color = const Color(0xFF030407));
    c.drawPath(pl, Paint()..color = const Color(0x24C8D0DE)..style = PaintingStyle.stroke);
    final ph = Path()..addPolygon([for (final q in hi) Offset(q[0], q[1])], true);
    final gr = R * c0[2] * 1.05;
    c.drawPath(ph, Paint()..shader = RadialGradient(colors: const [Color(0xFF171B28), Color(0xFF0C0E15), Color(0xFF07080C)], stops: const [0, .6, 1]).createShader(Rect.fromCircle(center: Offset(c0[0], c0[1]), radius: math.max(gr, 1))));
    c.drawPath(ph, Paint()..color = const Color(0x66CDD6E6)..style = PaintingStyle.stroke..strokeWidth = 1.3);
    const rg = [190.0, 205.0, 230.0];
    for (var i = 0; i < 3; i++) {
      ring(0, 0, [130.0, 230.0, 400.0][i], 0, rg, .07 + i * .02, 1);
    }
    final gp = Path();
    for (var q = -440.0; q <= 440; q += 88) {
      final e = math.sqrt(R * R - q * q) - 8, A = P(q, 0, -e), B = P(q, 0, e), C = P(-e, 0, q), D = P(e, 0, q);
      gp.moveTo(A[0], A[1]);
      gp.lineTo(B[0], B[1]);
      gp.moveTo(C[0], C[1]);
      gp.lineTo(D[0], D[1]);
    }
    c.drawPath(gp, Paint()..color = const Color(0x0DBECDE6)..style = PaintingStyle.stroke);
  }

  List<double> flow(int i, double u, double j) {
    final p = kEZP[i], ux = math.cos(p.a), uz = math.sin(p.a), S = kEZR - 66, E = 100.0, sx = ux * S, sz = uz * S, ex = ux * E, ez = uz * E, mx = (sx + ex) / 2, mz = (sz + ez) / 2;
    final t = kEZ[i].t == 'in' ? u : 1 - u, q = 1 - t, off = j * 12;
    return [q * q * sx + 2 * q * t * mx + t * t * ex - uz * off, q * q * 6 + 2 * q * t * 80 + t * t * 10, q * q * sz + 2 * q * t * mz + t * t * ez + ux * off];
  }

  void flows() {
    var mxv = 1.0;
    for (final z in kEZ) {
      mxv = math.max(mxv, s.m!.z[z.k] ?? 0);
    }
    for (var i = 0; i < kEZ.length; i++) {
      final z = kEZ[i], v = s.m!.z[z.k] ?? 0, inn = z.t == 'in', fr = math.min(1.0, v / mxv);
      final path = Path();
      for (var k = 0; k <= 20; k++) {
        final p = flow(i, k / 20, 0), q = P(p[0], p[1], p[2]);
        k == 0 ? path.moveTo(q[0], q[1]) : path.lineTo(q[0], q[1]);
      }
      c.drawPath(path, Paint()..color = inn ? Color.fromRGBO(170, 215, 255, .1 + .25 * fr) : Color.fromRGBO(230, 150, 100, .07 + .2 * fr)..style = PaintingStyle.stroke..strokeWidth = 1 + 2.2 * fr);
    }
    for (final q in s.parts) {
      final inn = kEZ[q.i].t == 'in', p = flow(q.i, q.t, q.j), sc = P(p[0], p[1], p[2]), al = math.sin(q.t * math.pi), rr = math.max(1.2, 2.4 * sc[2]);
      final rgb = inn ? const [170.0, 225.0, 255.0] : const [255.0, 170.0, 115.0];
      final pp = flow(q.i, math.max(0, q.t - .05), q.j), s2 = P(pp[0], pp[1], pp[2]);
      c.drawLine(Offset(s2[0], s2[1]), Offset(sc[0], sc[1]), Paint()..blendMode = BlendMode.plus..color = _emRgb(rgb, al * .5)..strokeWidth = rr..strokeCap = StrokeCap.round);
      halo(sc[0], sc[1], rr * 4, rgb, al * .5, add: true);
      c.drawCircle(Offset(sc[0], sc[1]), rr, Paint()..blendMode = BlendMode.plus..color = Colors.white.withOpacity(al.clamp(0.0, 1.0)));
    }
  }

  void tower() {
    final th = s.dp['th'] ?? 0, er = s.dp['er'] ?? 0, fh = 20.0, nF = math.max(1, (th / fh).ceil()), costH = math.min(1.0, er) * th, loss = er > 1.001, lit = s.dp['lit'] ?? .3, lvl = s.lvl;
    final lc = kEmLC[lvl], pul = .6 + .4 * math.sin(T * (2 + lvl * 3));
    final padPts = ringPts(0, 0, 100, 1.5, 48);
    final pp = Path()..addPolygon([for (final q in padPts) Offset(q[0], q[1])], true);
    c.drawPath(pp, Paint()..color = const Color(0xF2080A10));
    c.drawPath(pp, Paint()..color = const Color(0x80D2DCEC)..style = PaintingStyle.stroke..strokeWidth = 1.4);
    if (lvl > 0 || loss) {
      ring(0, 0, 108, 2, lc, .35 + .5 * pul, 2.4);
      final b0 = P(0, 0, 0);
      halo(b0[0], b0[1], 170 * b0[2], lc, .09 + .12 * pul * (lvl > 0 ? 1 : 0), add: true);
    }
    for (var i = 0; i < nF; i++) {
      final y0 = i * fh, y1 = math.min(th, (i + 1) * fh);
      if (y1 - y0 < .6) continue;
      final mid = (y0 + y1) / 2, w = hw(mid / math.max(th, 1)), cost = loss || mid < costH;
      final tint = loss ? const [168.0, 76.0, 74.0] : cost ? const [104.0, 114.0, 134.0] : const [178.0, 204.0, 234.0];
      final nhw = (i + 1) * fh >= th - .6 ? 0.0 : hw(((i + 1) * fh + math.min(th, (i + 2) * fh)) / 2 / math.max(th, 1));
      final bx = box(0, 0, w, y0, y1);
      final litCol = cost ? const Color(0xD9FFC88C) : const Color(0xE6F0F8FF);
      final nc = w >= 70 ? 8 : w >= 56 ? 6 : 5;
      for (var f = 0; f < 4; f++) {
        final q = face(bx, f, tint, .84, 1);
        if (q != null) {
          wins(q, nc, lit, i * 53 + f * 7, litCol);
          if (loss && i < 6) crack(q, i * 11 + f);
        }
      }
      if (nhw != w) top(bx, tint, .92, 1);
    }
    final sb = P(0, th, 0), st = P(0, th + 62, 0);
    c.drawLine(Offset(sb[0], sb[1]), Offset(st[0], st[1]), Paint()..color = const Color(0xE6E1EAF8)..strokeWidth = math.max(1.5, 2.2 * sb[2]));
    halo(st[0], st[1], 38 * st[2] + 6, lc, .35 + .4 * pul, add: true);
    c.drawCircle(Offset(st[0], st[1]), math.max(2.5, 4 * st[2]), Paint()..color = _emRgb(lc, 1));
    final mid2 = P(0, th / 2, 0);
    s.scr.add(_EmHit(kEZ.length, mid2[0], mid2[1], math.max(th / 2, 76) * mid2[2]));
    s.tow = (x: st[0], y: st[1], k: st[2]);
    if (s.sel == kEZ.length) ring(0, 0, 122, 3, const [240, 244, 250], .9, 1.6, dash: true);
  }

  void zone(int i) {
    final z = kEZ[i], p = kEZP[i], H = s.dp['z_${z.k}'] ?? 0, lvl = s.zl[z.k] ?? 0, sel = s.sel == i, lit = s.dp['lit'] ?? .3;
    final lc = kEmLC[lvl], pul = .6 + .4 * math.sin(T * (2 + lvl * 3));
    final pb = box(p.x, p.z, 64, 0, 4);
    for (var f = 0; f < 4; f++) {
      face(pb, f, const [24, 28, 40], .97, 1);
    }
    final tp = Path()..addPolygon([for (final q in pb.t) Offset(q[0], q[1])], true);
    c.drawPath(tp, Paint()..color = const Color(0xF710131C));
    c.drawPath(tp, Paint()..color = _emRgb(z.col, .7)..style = PaintingStyle.stroke..strokeWidth = 1.4);
    if (lvl > 0) ring(p.x, p.z, 76, 5, lc, .35 + .5 * pul, 2.2);
    final nF = math.max(1, (H / 16).ceil()), tint = _emMix(z.col, const [92, 102, 120], .5);
    final litCol = z.t == 'in' ? const Color(0xE6F0F8FF) : const Color(0xD9FFD096);
    for (var k = 0; k < nF; k++) {
      final y0 = 4 + k * 16.0, y1 = 4 + math.min(H, (k + 1) * 16.0);
      if (y1 - y0 < .6) continue;
      final bx = box(p.x, p.z, 40, y0, y1);
      for (var f = 0; f < 4; f++) {
        final q = face(bx, f, tint, .82, 1);
        if (q != null) wins(q, 4, lit, i * 91 + k * 53 + f * 7, litCol);
      }
      if (k == nF - 1 || (k + 1) * 16 >= H - .6) top(bx, tint, .92, 1);
    }
    final a0 = P(p.x, 4 + H, p.z), a1 = P(p.x, 4 + H + 26, p.z);
    c.drawLine(Offset(a0[0], a0[1]), Offset(a1[0], a1[1]), Paint()..color = const Color(0xD9E1EAF8)..strokeWidth = math.max(1.0, 1.6 * a0[2]));
    halo(a1[0], a1[1], 16 * a1[2] + 4, lvl > 0 ? lc : z.col, .55, add: true);
    c.drawCircle(Offset(a1[0], a1[1]), math.max(2, 3 * a1[2]), Paint()..color = _emRgb(lvl > 0 ? lc : z.col, 1));
    final mid = P(p.x, 4 + H / 2, p.z);
    s.scr.add(_EmHit(i, mid[0], mid[1], math.max(H / 2, 62) * mid[2]));
    s.lab[i] = Offset(a1[0], a1[1]);
    if (sel) ring(p.x, p.z, 88, 6, const [240, 244, 250], .9, 1.6, dash: true);
  }

  void label(double x, double y, String t1, String t2, List<double> rgb, int lvl, double al) {
    final tp1 = TextPainter(text: TextSpan(text: t1, style: const TextStyle(color: Color(0xFFF1F4FA), fontSize: 11, fontWeight: FontWeight.w700)), textDirection: TextDirection.ltr)..layout();
    final tp2 = t2.isEmpty ? null : (TextPainter(text: TextSpan(text: t2, style: TextStyle(color: _emRgb(rgb, 1), fontSize: 10, fontWeight: FontWeight.w600)), textDirection: TextDirection.ltr)..layout());
    final pw = math.max(tp1.width, tp2?.width ?? 0) + 18 + (lvl > 0 ? 14 : 0), ph = tp2 != null ? 34.0 : 22.0;
    x = math.max(pw / 2 + 4, math.min(s.w - pw / 2 - 4, x));
    y = math.max(ph + 4, y - 14);
    c.saveLayer(Rect.fromLTWH(x - pw / 2 - 2, y - ph - 2, pw + 4, ph + 4), Paint()..color = Colors.white.withOpacity(al.clamp(0.0, 1.0)));
    final rr = RRect.fromRectAndRadius(Rect.fromLTWH(x - pw / 2, y - ph, pw, ph), const Radius.circular(10));
    c.drawRRect(rr, Paint()..color = const Color(0xE0080A10));
    c.drawRRect(rr, Paint()..color = _emRgb(rgb, .75)..style = PaintingStyle.stroke..strokeWidth = 1.2);
    final tx = x + (lvl > 0 ? 7 : 0);
    tp1.paint(c, Offset(tx - tp1.width / 2, y - ph + (tp2 != null ? 12 : 11) - tp1.height / 2));
    tp2?.paint(c, Offset(tx - tp2.width / 2, y - ph + 25 - tp2.height / 2));
    if (lvl > 0) {
      c.drawCircle(Offset(x - pw / 2 + 13, y - ph / 2), 6, Paint()..color = _emRgb(kEmLC[lvl], 1));
      final ex = TextPainter(text: const TextSpan(text: '!', style: TextStyle(color: Color(0xFF0B0C10), fontSize: 9, fontWeight: FontWeight.w800)), textDirection: TextDirection.ltr)..layout();
      ex.paint(c, Offset(x - pw / 2 + 13 - ex.width / 2, y - ph / 2 - ex.height / 2));
    }
    c.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    c = canvas;
    s.w = size.width;
    s.h = size.height;
    T = s.t;
    final w = s.w, h = s.h;
    c.drawRect(Offset.zero & size, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF05070D), Color(0xFF090C16)]).createShader(Offset.zero & size));
    if (s.m == null) return;
    halo(w * .5 + math.cos(T * .05) * 30, h * .22, w * .7, const [120, 140, 190], .1, add: true);
    for (final st in s.stars) {
      final tw = .5 + .5 * math.sin(T * 1.5 + st.tw), px = (((st.x - s.yaw * st.d * 80) % w) + w) % w;
      c.drawRect(Rect.fromLTWH(px, st.y, st.d * 1.6, st.d * 1.6), Paint()..color = const Color(0xFFE1E8F8).withOpacity((.7 * st.d * tw).clamp(0.0, 1.0)));
    }
    s.scr = [];
    s.lab = {};
    s.tow = null;
    ground();
    flows();
    final items = <({double z, int i})>[(z: P(0, 0, 0)[3], i: -1)];
    for (var i = 0; i < kEZ.length; i++) {
      items.add((z: P(kEZP[i].x, 0, kEZP[i].z)[3], i: i));
    }
    items.sort((a, b) => b.z.compareTo(a.z));
    for (final it in items) {
      it.i < 0 ? tower() : zone(it.i);
    }
    final sl = s.sel, m = s.m!;
    for (var i = 0; i < kEZ.length; i++) {
      final p = s.lab[i];
      if (p == null) continue;
      label(p.dx, p.dy, kEZ[i].n, s.empty ? '' : eShort(m.z[kEZ[i].k] ?? 0), kEZ[i].col, s.zl[kEZ[i].k] ?? 0, sl < 0 || sl == i ? 1 : .4);
    }
    if (s.tow != null) {
      label(s.tow!.x, s.tow!.y - 6, 'BIZNES MINORASI', s.empty ? '' : 'Foyda ${m.p < 0 ? '−' : ''}${eShort(m.p.abs())}', m.p < 0 ? const [255, 140, 125] : const [200, 225, 255], s.lvl, sl < 0 || sl == kEZ.length ? 1 : .4);
    }
  }

  @override
  bool shouldRepaint(covariant _EmPainter o) => true;
}

class _EmTlPainter extends CustomPainter {
  final List<_EmM> ser;
  final int idx;
  _EmTlPainter(this.ser, this.idx);
  @override
  void paint(Canvas c, Size size) {
    final n = ser.length;
    if (n == 0) return;
    final W = size.width, H = size.height, pl = 8.0, pr = 8.0, pt = 14.0, pb = 24.0, pw = W - pl - pr, ph = H - pt - pb;
    var hi = 1.0, lo = 0.0;
    for (final d in ser) {
      hi = math.max(hi, math.max(d.i, d.o));
      lo = math.min(lo, d.p);
    }
    final pad = (hi - lo) * .08;
    hi += pad;
    if (lo < 0) lo -= pad;
    double Y(double v) => pt + ph * (1 - (v - lo) / (hi - lo));
    final band = pw / n, bw = math.min(18.0, band * .3), z0 = Y(0);
    c.drawLine(Offset(pl, z0), Offset(W - pr, z0), Paint()..color = const Color(0x40C8D0DE));
    final line = Path();
    for (var k = 0; k < n; k++) {
      final d = ser[k], cx = pl + band * k + band / 2, sel = k == idx, mi = int.parse(d.mk.substring(5, 7));
      if (sel) c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - band / 2, pt - 6, band, ph + 10), const Radius.circular(8)), Paint()..color = const Color(0x17DCE6F5));
      final yi = Y(d.i), yo = Y(d.o);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - bw - 1, yi, bw, math.max(0.0, z0 - yi)), const Radius.circular(3)), Paint()..color = const Color(0xFFCDD6E4).withOpacity(sel ? 1 : .7));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 1, yo, bw, math.max(0.0, z0 - yo)), const Radius.circular(3)), Paint()..color = const Color(0xFFC98A5A).withOpacity(sel ? 1 : .7));
      k == 0 ? line.moveTo(cx, Y(d.p)) : line.lineTo(cx, Y(d.p));
      final tp = TextPainter(text: TextSpan(text: monthName(mi).substring(0, math.min(3, monthName(mi).length)), style: TextStyle(fontSize: 10, fontWeight: sel ? FontWeight.w800 : FontWeight.w600, color: sel ? Colors.white : const Color(0xFF8F98A8))), textDirection: TextDirection.ltr)..layout();
      tp.paint(c, Offset(cx - tp.width / 2, H - 7 - tp.height / 2));
    }
    c.drawPath(line, Paint()..color = const Color(0xFF7FE0B4)..style = PaintingStyle.stroke..strokeWidth = 2..strokeJoin = StrokeJoin.round..strokeCap = StrokeCap.round);
    for (var k = 0; k < n; k++) {
      final d = ser[k], cx = pl + band * k + band / 2;
      c.drawCircle(Offset(cx, Y(d.p)), k == idx ? 4.5 : 3, Paint()..color = d.p < 0 ? const Color(0xFFFF7A6B) : const Color(0xFF7FE0B4));
    }
  }

  @override
  bool shouldRepaint(covariant _EmTlPainter o) => true;
}

class EmpireTab extends StatefulWidget {
  final ShellApi api;
  const EmpireTab({super.key, required this.api});
  @override
  State<EmpireTab> createState() => _EmpireTabState();
}

class _EmpireTabState extends State<EmpireTab> with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(vsync: this, duration: const Duration(seconds: 3600))..repeat();
  final s = _EmS();
  final rnd = math.Random();
  final bud = TextEditingController();
  double _last = 0, _zs = 1;
  bool _hint = true, _sized = false, _ready = false;

  Profile get p => app.profile!;

  @override
  void initState() {
    super.initState();
    final B = p.mp('biz');
    final bv = ((B['budget'] ?? 0) as num).toDouble();
    bud.text = bv > 0 ? '${bv % 1 == 0 ? bv.toInt() : bv}' : '';
    s.mk = monthKeyOf(DateTime.now());
    s.chk = .8;
    _refresh();
    _ready = true;
    _ac.addListener(_tick);
    Future<void>.delayed(const Duration(seconds: 6), () {
      if (mounted) setState(() => _hint = false);
    });
  }

  @override
  void dispose() {
    _ac.dispose();
    bud.dispose();
    super.dispose();
  }

  List<String> _keys() {
    final k = <String>[];
    var m = monthKeyOf(DateTime.now());
    for (var i = 0; i < 12; i++) {
      k.insert(0, m);
      m = prevMonthKey(m);
    }
    return k;
  }

  void _refresh() {
    final ks = _keys(), ser = [for (final k in ks) _emMon(s, k)];
    if (!ks.contains(s.mk)) s.mk = ks.last;
    final idx = ks.indexOf(s.mk), m = ser[idx], pm = idx > 0 ? ser[idx - 1] : _emMon(s, prevMonthKey(s.mk));
    final x = _emCtx(s)..now = s.mk == monthKeyOf(DateTime.now());
    final R = _emRisks(m, pm, x);
    var sc = 100;
    for (final r in R) {
      sc -= r.l == 2 ? 28 : 11;
    }
    s.ks = ks;
    s.ser = ser;
    s.idx = idx;
    s.m = m;
    s.pm = pm;
    s.ctx = x;
    s.R = R;
    s.score = math.max(0, sc);
    s.lvl = R.isNotEmpty ? R[0].l : 0;
    s.zl = {};
    for (final r in R) {
      if (r.z.isNotEmpty && (s.zl[r.z] ?? 0) < r.l) s.zl[r.z] = r.l;
    }
    s.empty = !s.demo && !ser.any((e) => e.n > 0);
    var refR = 1.0, refZ = 1.0;
    for (final e in ser) {
      refR = math.max(refR, e.i);
      for (final z in kEZ) {
        refZ = math.max(refZ, e.z[z.k] ?? 0);
      }
    }
    final T = <String, double>{}, emp = s.empty;
    T['th'] = emp ? 40 : (m.i > 0 ? 70 + 350 * math.min(1.0, m.i / refR) : 60);
    T['er'] = m.i > 0 ? math.min(1.25, m.o / m.i) : (m.o > 0 ? 1.25 : 0);
    T['lit'] = emp ? .12 : math.min(.9, .3 + .6 * math.min(1.0, m.n / 30));
    for (final z in kEZ) {
      final v = m.z[z.k] ?? 0;
      T['z_${z.k}'] = emp ? 8 : (v > 0 ? 20 + 200 * math.pow(v / refZ, .8) : 9);
    }
    s.tg = T;
    final sig = '${s.mk}|${s.demo}|${m.i}|${m.o}|${m.n}|${R.length}|${s.lvl}|${[for (final e in ser) '${e.i}/${e.o}'].join(',')}|${x.on}|${x.od}|${x.bud}|${x.pend}|${app.cur}|${s.sel}';
    if (sig != s.sig) {
      s.sig = sig;
      if (_ready && mounted) setState(() {});
    }
  }

  void _tick() {
    final now = _ac.value * 3600.0;
    var dt = now - _last;
    if (dt < 0) dt += 3600;
    _last = now;
    dt = math.min(.05, dt);
    s.t += dt;
    final a = 1 - math.exp(-dt * 3.2), sl = s.sel;
    double tx = 0, tz = 0, fy = 150, zt = 1;
    s.intro = math.min(1.0, s.intro + dt / 3.2);
    s.ib = 1 - math.pow(1 - s.intro, 3).toDouble();
    if (sl >= 0 && sl < kEZ.length) {
      tx = kEZP[sl].x;
      tz = kEZP[sl].z;
      fy = math.min(110.0, (s.dp['z_${kEZ[sl].k}'] ?? 20) * .5);
      zt = 1.9;
    } else if (sl == kEZ.length) {
      fy = 190;
      zt = 1.45;
    }
    s.fx += (tx - s.fx) * a;
    s.fz += (tz - s.fz) * a;
    s.fy += (fy - s.fy) * a;
    s.zoom += (s.uz * zt - s.zoom) * a;
    if (!_drag) {
      s.yaw += s.vel * dt;
      s.vel *= math.exp(-dt * 2.2);
      if (sl < 0) s.yaw += dt * (s.film ? .24 : .06);
    }
    s.pitch = s.pitch.clamp(.14, 1.2);
    s.sc = math.min(s.w, s.h * 1.15) / 1000 * s.zoom * (.4 + .6 * s.ib);
    s.chk -= dt;
    if (s.chk <= 0) {
      s.chk = .8;
      _refresh();
    }
    if (s.play) {
      s.playT -= dt;
      if (s.playT <= 0) {
        s.playT = 1.1;
        var i = s.idx + 1;
        if (i >= s.ks.length) i = 0;
        s.mk = s.ks[i];
        _refresh();
        if (mounted) setState(() {});
      }
    }
    final b = 1 - math.exp(-dt * (s.intro < 1 ? 1.5 : 3.6));
    for (final k in s.tg.keys) {
      s.dp[k] = (s.dp[k] ?? 0) + (s.tg[k]! - (s.dp[k] ?? 0)) * b;
    }
    s.spawn -= dt;
    if (s.spawn <= 0 && s.intro > .45 && !s.empty && s.m != null) {
      s.spawn = .07;
      var mxv = 1.0;
      for (final z in kEZ) {
        mxv = math.max(mxv, s.m!.z[z.k] ?? 0);
      }
      for (var i = 0; i < kEZ.length; i++) {
        final v = s.m!.z[kEZ[i].k] ?? 0;
        if (v > 0 && rnd.nextDouble() < .12 + .5 * v / mxv) s.parts.add(_EmPart(i, .16 + rnd.nextDouble() * .2, rnd.nextDouble() * 2 - 1));
      }
      if (s.parts.length > 170) s.parts.removeRange(0, 30);
    }
    for (final q in s.parts) {
      q.t += q.sp * dt;
    }
    s.parts.removeWhere((q) => q.t >= 1);
  }

  bool _drag = false;

  void _pick(Offset pos) {
    var best = -1;
    var bd = 1e9;
    for (final h in s.scr) {
      final d = math.sqrt(math.pow(pos.dx - h.x, 2) + math.pow(pos.dy - h.y, 2)) / math.max(h.r, 1);
      if (d < 1.15 && d < bd) {
        bd = d;
        best = h.i;
      }
    }
    if (best >= 0) _sel(best);
  }

  void _sel(int i) {
    s.sel = i == s.sel ? -1 : i;
    _hint = false;
    s.sig = '';
    setState(() {});
  }

  String _dl(double a, double b) => b > 0 ? "${a >= b ? '↑ +' : '↓ −'}${((a / b - 1) * 100).abs().round()}% o'tgan oyga nisbatan" : "O'tgan oyda ma'lumot yo'q";

  Widget _kpi(String a, String b, String sub, [Color? col]) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color(0x0AFFFFFF), border: Border.all(color: C.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a, style: const TextStyle(color: C.dim, fontSize: 11.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(b, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: col))),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(color: C.mute, fontSize: 10.5), maxLines: 2, overflow: TextOverflow.ellipsis),
        ]),
      );

  Widget _alert(_EmRisk r) {
    final col = r.l == 2 ? const Color(0xFFFF7A6B) : r.l == 1 ? const Color(0xFFF2B84A) : const Color(0xFF7FE0B4);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: col.withOpacity(.08), border: Border.all(color: col.withOpacity(.4))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r.t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)), Text(r.d, style: const TextStyle(color: C.dim, fontSize: 12))]),
    );
  }

  Widget _info() {
    final m = s.m!, pm = s.pm!, sl = s.sel;
    if (sl < 0) {
      return uCard('Boshqaruv markazi · ${mlab(s.mk)}', children: [uSmall("Minorani yoki bo'limni bosing, kamera unga uchib boradi. Minora balandligi tushumga bog'liq: kumush qavatlar foyda, to'q qavatlar xarajat ulushi, qizil rang esa zarar. Yer ustidagi oqimlar: kumush-ko'k kirim, mis rang chiqim.")]);
    }
    if (sl == kEZ.length) {
      final mg = m.i > 0 ? (m.p / m.i * 100).round() : null;
      return uCard('Biznes minorasi · ${mlab(s.mk)}', children: [
        URow(title: 'Tushum', sub: _dl(m.i, pm.i), amount: mny(m.i)),
        URow(title: 'Xarajat', sub: m.i > 0 ? "Tushumning ${(m.o / m.i * 100).round()}% i" : null, amount: mny(m.o), amountColor: m.o > m.i ? C.out : null),
        URow(title: 'Foyda', sub: mg == null ? "Tushum yo'q" : 'Marja $mg%', amount: sgn(m.p), amountColor: m.p < 0 ? C.out : C.accent),
        URow(title: 'Operatsiyalar', sub: 'Shu oy biznes yozuvlari', amount: '${m.n}'),
        URow(title: "Kutilayotgan to'lovlar", sub: s.ctx.on > 0 ? 'Kechikkan: ${mny(s.ctx.od)} (${s.ctx.on} ta)' : 'Kechikish yo\'q', amount: mny(s.ctx.pend), amountColor: s.ctx.on > 0 ? C.warn : null),
        URow(title: 'Risk balli', sub: s.R.isNotEmpty ? '${s.R.length} ta ogohlantirish' : "Hammasi me'yorda", amount: '${s.score} / 100'),
      ]);
    }
    final z = kEZ[sl], v = m.z[z.k] ?? 0, pv = pm.z[z.k] ?? 0;
    final kids = <Widget>[];
    if (z.t == 'in') {
      kids.addAll([
        URow(title: 'Tushum', sub: _dl(v, pv), amount: mny(v)),
        URow(title: "Kutilayotgan to'lovlar", sub: 'Hisob-fakturalar bo\'yicha', amount: mny(s.ctx.pend)),
        URow(title: 'Kechikkan', sub: '${s.ctx.on} ta hisob-faktura', amount: mny(s.ctx.od), amountColor: s.ctx.on > 0 ? C.out : null),
      ]);
    } else {
      kids.addAll([
        URow(title: 'Xarajat', sub: _dl(v, pv), amount: mny(v)),
        URow(title: 'Xarajatdagi ulushi', sub: 'Jami xarajatga nisbatan', amount: m.o > 0 ? '${(v / m.o * 100).round()}%' : '—'),
        URow(title: 'Tushumdagi ulushi', sub: "Har 100 so'm tushumdan", amount: m.i > 0 ? '${(v / m.i * 100).round()}%' : '—'),
      ]);
      for (final c in z.cats) {
        final lim = s.ctx.lim[c] ?? 0, u = m.cc[c] ?? 0;
        if (lim > 0) {
          final pc = math.min(100.0, u / lim * 100);
          kids.add(URow(title: 'Kategoriya limiti', sub: '${mny(u)} / ${mny(lim)}', amount: '${(u / lim * 100).round()}%', amountColor: u > lim ? C.out : null));
          kids.add(Padding(padding: const EdgeInsets.only(bottom: 8), child: uBar(pc / 100, u > lim ? C.out : pc >= 80 ? C.warn : C.accent)));
        } else {
          kids.add(const URow(title: 'Kategoriya limiti', sub: "Profil → Tarif va limit bo'limida qo'ying", amount: 'Belgilanmagan'));
        }
      }
    }
    if (!s.demo) {
      Tx? best;
      for (final x in app.listOf(s.mk)) {
        if (x.ex['b'] == null) continue;
        if ((z.t == 'in' ? x.t == 'in' : x.t == 'out' && _emZk(x.c) == z.k) && (best == null || x.a > best.a)) best = x;
      }
      if (best != null) kids.add(URow(title: 'Eng katta yozuv', sub: '${best.d}${best.n.isNotEmpty ? ' · ${best.n}' : ''}', amount: mny(best.a)));
    }
    for (final r in s.R.where((r) => r.z == z.k)) {
      kids.add(_alert(r));
    }
    return uCard('${z.n} · ${mlab(s.mk)}', children: kids);
  }

  List<Widget> _events() {
    final mk = s.mk, m = s.m!, pm = s.pm!;
    final ev = <({String d, String t, String s, Color c})>[];
    if (s.demo) {
      String d(int n) => '$mk-${two(math.min(daysIn(int.parse(mk.substring(0, 4)), int.parse(mk.substring(5, 7))), n))}';
      ev.addAll([
        (d: d(3), t: 'Hisob-faktura INV-0${40 + s.idx} yaratildi', s: 'Mijoz: Orzu Trade · ${mny(m.i * .18)}', c: const Color(0xFFCFD8E6)),
        (d: d(8), t: 'Katta xarajat: tovar xaridi', s: mny(m.z['stock']! * .45), c: const Color(0xFFE0A066)),
        (d: d(14), t: "To'lov qabul qilindi", s: 'Mijoz: Silk Road · ${mny(m.i * .12)}', c: const Color(0xFF7FE0B4)),
        (d: d(20), t: "Ish haqi to'landi", s: mny(m.z['pay']!), c: const Color(0xFFE0A066)),
        (d: d(25), t: 'Marketing kampaniyasi', s: mny(m.z['ads']! * .6), c: const Color(0xFFE0A066)),
      ]);
    } else {
      for (final v in p.lst('inv')) {
        final dt = '${v['date'] ?? ''}', pa = '${v['paidAt'] ?? ''}';
        final tot = ((v['total'] ?? 0) as num).toDouble(), paid = ((v['paid'] ?? 0) as num).toDouble();
        if (dt.length >= 7 && dt.substring(0, 7) == mk) ev.add((d: dt, t: 'Hisob-faktura ${v['no']} yaratildi', s: '${v['client']} · ${mny(tot)}', c: const Color(0xFFCFD8E6)));
        if (pa.length >= 7 && pa.substring(0, 7) == mk && paid >= tot - .001) ev.add((d: pa, t: "To'liq to'langan: ${v['no']}", s: '${v['client']} · ${mny(tot)}', c: const Color(0xFF7FE0B4)));
      }
      for (final t in ['in', 'out']) {
        final l = app.listOf(mk).where((x) => x.ex['b'] != null && x.t == t).toList()..sort((a, b) => b.a.compareTo(a.a));
        for (final x in l.take(3)) {
          ev.add((d: x.d, t: '${t == 'in' ? 'Katta tushum: ' : 'Katta xarajat: '}${catsOf(t).firstWhere((c) => c.id == x.c, orElse: () => catsOf(t).last).name}', s: '${x.n.isNotEmpty ? '${x.n} · ' : ''}${mny(x.a)}', c: t == 'in' ? const Color(0xFF7FE0B4) : const Color(0xFFE0A066)));
        }
      }
    }
    ev.sort((a, b) => b.d.compareTo(a.d));
    final out = ev.take(8).toList();
    return [
      Padding(padding: const EdgeInsets.only(top: 10, bottom: 6), child: Text("${mlab(mk)}: foyda ${sgn(m.p)}${pm.p != 0 || pm.i > 0 ? " · o'tgan oy ${sgn(pm.p)}" : ''}", style: const TextStyle(color: C.dim, fontSize: 12.5))),
      if (out.isEmpty) uSmall("Bu oyda yozuv yo'q."),
      for (final e in out)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: const EdgeInsets.only(top: 5, right: 10), child: CircleAvatar(radius: 4, backgroundColor: e.c)),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)), Text('${e.d} · ${e.s}', style: const TextStyle(color: C.dim, fontSize: 12))])),
          ]),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final m = s.m!, pm = s.pm!;
    final mg = m.i > 0 ? (m.p / m.i * 100).round() : null;
    final rc = s.lvl == 2 ? const Color(0xFFFF7A6B) : s.lvl == 1 ? const Color(0xFFF2B84A) : const Color(0xFF7FE0B4);
    final lg = [(const Color(0xFFB2CCEA), 'Foyda'), (const Color(0xFF7A869B), 'Xarajat'), (const Color(0xFFA84C4A), 'Zarar')];
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
      const Text('VAULT EMPIRE', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const Text('Business Exclusive', style: TextStyle(color: C.dim, fontSize: 13.5)),
      const SizedBox(height: 12),
      if (s.empty || s.demo)
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: C.warn.withOpacity(.1), border: Border.all(color: C.warn.withOpacity(.4))),
          child: Row(children: [
            Expanded(child: Text(s.empty ? "Hali biznes ma'lumoti yo'q. «Biznes» bo'limidan operatsiya qo'shing yoki demo bilan ko'ring." : "Demo rejim: namunaviy ma'lumot, hisobingizga ta'sir qilmaydi.", style: const TextStyle(fontSize: 12.5))),
            TextButton(onPressed: _toggleDemo, child: Text(s.empty ? "Demo ko'rsatish" : "Demo'ni o'chirish")),
          ]),
        ),
      ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 460,
          child: LayoutBuilder(builder: (ctx, bc) {
            if (!_sized || s.w != bc.maxWidth) {
              _sized = true;
              s.w = bc.maxWidth;
              s.h = 460;
              s.stars = [for (var i = 0; i < 140; i++) _EmStar(rnd.nextDouble() * s.w, rnd.nextDouble() * s.h * .6, .2 + rnd.nextDouble() * .8, rnd.nextDouble() * 6)];
            }
            return Stack(fit: StackFit.expand, children: [
              GestureDetector(
                onScaleStart: (d) {
                  _drag = true;
                  _zs = s.uz;
                  s.vel = 0;
                },
                onScaleUpdate: (d) {
                  if (d.pointerCount >= 2) {
                    s.uz = (_zs * d.scale).clamp(.6, 2.4);
                  } else {
                    s.yaw += d.focalPointDelta.dx * .006;
                    s.pitch += d.focalPointDelta.dy * .004;
                    s.vel = (d.focalPointDelta.dx * .006 * 60).clamp(-3.0, 3.0);
                  }
                },
                onScaleEnd: (_) => _drag = false,
                onTapUp: (d) => _pick(d.localPosition),
                child: CustomPaint(painter: _EmPainter(s, _ac)),
              ),
              Positioned(
                left: 14,
                top: 12,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${mlab(s.mk)}${s.demo ? ' · DEMO' : ''}', style: const TextStyle(color: C.dim, fontSize: 10.5, letterSpacing: 1.4, fontWeight: FontWeight.w700)),
                  Text(s.empty ? '—' : sgn(m.p), style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: m.p < 0 ? const Color(0xFFFF9A8E) : null)),
                  Text(s.empty ? "Biznes ma'lumoti yo'q" : 'Tushum ${eShort(m.i)} · Xarajat ${eShort(m.o)}', style: const TextStyle(color: Color(0xFFA9B1C0), fontSize: 12)),
                  const SizedBox(height: 6),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: rc.withOpacity(.14), border: Border.all(color: rc.withOpacity(.6))), child: Text('${s.lvl == 2 ? 'RISK YUQORI' : s.lvl == 1 ? "RISK O'RTACHA" : 'RISK PAST'} · ${s.score}', style: TextStyle(color: rc, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: .8))),
                ]),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Column(children: [
                  _eb('＋', () => s.uz = math.min(2.4, s.uz * 1.2)),
                  _eb('－', () => s.uz = math.max(.6, s.uz / 1.2)),
                  _eb('↺', () {
                    s.uz = 1;
                    s.yaw = .62;
                    s.pitch = .52;
                    s.vel = 0;
                    s.film = false;
                  }),
                  _eb('▶', () {
                    s.sel = -1;
                    s.uz = 1;
                    s.film = !s.film;
                    s.intro = 0;
                    s.dp = {};
                    s.parts = [];
                    s.sig = '';
                  }),
                ]),
              ),
              Positioned(left: 12, bottom: 10, child: Row(children: [for (final e in lg) Padding(padding: const EdgeInsets.only(right: 10), child: Row(children: [Container(width: 9, height: 9, decoration: BoxDecoration(color: e.$1, borderRadius: BorderRadius.circular(3))), const SizedBox(width: 4), Text(e.$2, style: const TextStyle(fontSize: 10.5, color: C.dim))]))])),
              if (_hint) const Positioned(left: 0, right: 0, bottom: 30, child: Center(child: Text("SUDRAB AYLANTIRING · YAQINLASHTIRING · BO'LIMNI TANLANG", style: TextStyle(color: C.mute, fontSize: 10, letterSpacing: 1.1)))),
            ]);
          }),
        ),
      ),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        ChoiceChip(avatar: const CircleAvatar(radius: 5, backgroundColor: Color(0xFFE8ECF3)), label: const Text('Minora'), selected: s.sel == kEZ.length, onSelected: (_) => _sel(kEZ.length)),
        for (var i = 0; i < kEZ.length; i++) ChoiceChip(avatar: CircleAvatar(radius: 5, backgroundColor: _emRgb(kEZ[i].col, 1)), label: Text(kEZ[i].n), selected: s.sel == i, onSelected: (_) => _sel(i)),
      ]),
      const SizedBox(height: 12),
      GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.9, children: [
        _kpi('Tushum', mny(m.i), _dl(m.i, pm.i)),
        _kpi('Xarajat', mny(m.o), _dl(m.o, pm.o)),
        _kpi('Foyda', sgn(m.p), mg == null ? "Tushum yo'q" : 'Marja $mg%', m.p < 0 ? const Color(0xFFFF7A6B) : null),
        _kpi('Risk balli', '${s.score} / 100', s.R.isNotEmpty ? '${s.R.length} ta ogohlantirish' : "Hammasi me'yorda", rc),
      ]),
      const SizedBox(height: 12),
      _info(),
      uCard('Business Timeline', sub: '12 oy', children: [
        LayoutBuilder(builder: (ctx, bc) => GestureDetector(
              onTapUp: (d) {
                final i = ((d.localPosition.dx - 8) / ((bc.maxWidth - 16) / s.ser.length)).floor().clamp(0, s.ser.length - 1);
                s.mk = s.ks[i];
                s.play = false;
                _refresh();
                setState(() {});
              },
              child: SizedBox(height: 170, width: bc.maxWidth, child: CustomPaint(painter: _EmTlPainter(s.ser, s.idx))),
            )),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (final e in [(const Color(0xFFCDD6E4), 'Tushum'), (const Color(0xFFC98A5A), 'Xarajat'), (const Color(0xFF7FE0B4), 'Foyda')]) Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Row(children: [CircleAvatar(radius: 4, backgroundColor: e.$1), const SizedBox(width: 4), Text(e.$2, style: const TextStyle(color: C.dim, fontSize: 11))])),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          SizedBox(width: 150, child: uBtn(s.play ? "❚❚ To'xtatish" : '▶ Tarixni ijro etish', () {
            s.play = !s.play;
            s.playT = 0;
            setState(() {});
          }, ghost: true)),
          Expanded(child: Slider(value: s.idx.toDouble(), min: 0, max: math.max(1, s.ks.length - 1).toDouble(), divisions: math.max(1, s.ks.length - 1), onChanged: (v) {
            s.mk = s.ks[v.round()];
            s.play = false;
            _refresh();
            setState(() {});
          })),
        ]),
        Center(child: Text(mlab(s.mk), style: const TextStyle(color: C.dim, fontSize: 12))),
        ..._events(),
      ]),
      uCard('Risk indikatorlari', sub: 'limitlar va muddatlar', children: [
        Row(children: [
          Container(width: 56, height: 56, alignment: Alignment.center, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: rc, width: 4)), child: Text('${s.score}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.lvl == 2 ? 'Yuqori risk' : s.lvl == 1 ? "O'rtacha risk" : 'Risk past', style: const TextStyle(fontWeight: FontWeight.w800)), Text(s.R.isNotEmpty ? '${s.R.length} ta ogohlantirish · ${mlab(s.mk)}' : "Limit va muddatlar me'yorda · ${mlab(s.mk)}", style: const TextStyle(color: C.dim, fontSize: 12))])),
        ]),
        const SizedBox(height: 10),
        if (s.R.isEmpty) _alert(_EmRisk(0, "Hamma ko'rsatkichlar me'yorda. Shu tempni saqlang.", '')) else ...s.R.map(_alert),
      ]),
      uCard('Sozlamalar', children: [
        uSmall("Kategoriya limitlari: Profil → Tarif va limit. Bu yerda umumiy oylik xarajat byudjetini belgilang, oshganda minora va bo'lim qizil ogohlantiradi."),
        uField(bud, 'Oylik xarajat byudjeti', num: true),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: uBtn('Saqlash', _saveBud)),
          const SizedBox(width: 8),
          SizedBox(width: 100, child: uBtn('Demo', _toggleDemo, ghost: true)),
        ]),
      ]),
      const Center(child: Padding(padding: EdgeInsets.only(top: 6), child: Text('VAULT EMPIRE — Build. Manage. Grow. · FROM EIGHTEEN.', style: TextStyle(color: C.mute, fontSize: 11, letterSpacing: 1.1)))),
    ]);
  }

  void _toggleDemo() {
    s.demo = !s.demo;
    s.sig = '';
    s.parts = [];
    _refresh();
    setState(() {});
  }

  Future<void> _saveBud() async {
    final v = bud.text.trim().isEmpty ? 0.0 : parseAmount(bud.text);
    if (v == null || v < 0) return toast(context, 'Byudjetni raqam bilan kiriting.');
    p.mp('biz')['budget'] = v;
    await app.saveProfile();
    s.sig = '';
    _refresh();
    if (mounted) {
      setState(() {});
      toast(context, v > 0 ? 'Oylik byudjet saqlandi' : "Byudjet o'chirildi");
    }
  }

  Widget _eb(String l, VoidCallback f) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: GestureDetector(onTap: () => setState(f), child: Container(width: 36, height: 36, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10), border: Border.all(color: C.line)), child: Text(l, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)))),
      );
}

/* ====================================================================== */
/*  VAULT GENESIS (Free Exclusive): 3D crystal tied to a savings goal      */
/* ====================================================================== */
const Map<String, ({int n, List<List<double>> r})> kGnSh = {
  'brilliant': (n: 8, r: [[1, .5, 0], [.42, 1, 0], [.28, 1, 0], [-1.4, 0, 0]]),
  'obelisk': (n: 6, r: [[1.55, 0, 0], [1.05, .45, 0], [-1.1, .5, 0], [-1.1, 0, 0]]),
  'oktaedr': (n: 4, r: [[1.4, 0, 0], [0, 1, 0], [-1.4, 0, 0]]),
  'shard': (n: 5, r: [[1.6, 0, 0], [.55, .55, .3], [-.5, .85, 0], [-1.5, 0, 0]]),
};
const Map<String, String> kGnN = {'brilliant': 'Brilliant', 'obelisk': 'Obelisk', 'oktaedr': 'Oktaedr', 'shard': 'Shard'};
const Map<String, (String, Color)> kGnT = {'silver': ('Kumush', Color(0xFFCED6E8)), 'ice': ('Muz', Color(0xFF8CC6FF)), 'violet': ('Binafsha', Color(0xFFBEA0FF))};
const List<(double, String, String)> kGnM = [(.25, '25%', 'Boshlanish uchquni'), (.5, '50%', "Yarim yo'l"), (.75, '75%', 'Yakuniga oz qoldi'), (1, '100%', 'Maqsadga erishildi')];
const Color kGnGold = Color(0xFFFFD68C);

class _GnGeo {
  final List<List<double>> v = [];
  final List<List<int>> f = [];
}

_GnGeo _gnGeo(({int n, List<List<double>> r}) sh) {
  final g = _GnGeo();
  final rows = <({int? a, List<int>? r})>[];
  final n = sh.n;
  for (final rg in sh.r) {
    final y = rg[0], rad = rg[1], rot = rg[2];
    if (rad == 0) {
      g.v.add([0, y, 0]);
      rows.add((a: g.v.length - 1, r: null));
    } else {
      final row = <int>[];
      for (var k = 0; k < n; k++) {
        final an = (k + rot * .5) / n * math.pi * 2;
        g.v.add([math.cos(an) * rad, y, math.sin(an) * rad]);
        row.add(g.v.length - 1);
      }
      rows.add((a: null, r: row));
    }
  }
  for (var i = 0; i < rows.length - 1; i++) {
    final A = rows[i], B = rows[i + 1];
    for (var k = 0; k < n; k++) {
      final k2 = (k + 1) % n;
      if (A.a != null && B.r != null) {
        g.f.add([A.a!, B.r![k], B.r![k2]]);
      } else if (B.a != null && A.r != null) {
        g.f.add([A.r![k], A.r![k2], B.a!]);
      } else if (A.r != null && B.r != null) {
        g.f.add([A.r![k], A.r![k2], B.r![k2], B.r![k]]);
      }
    }
  }
  if (rows.first.r != null) g.f.add(List<int>.from(rows.first.r!));
  if (rows.last.r != null) g.f.add(List<int>.from(rows.last.r!.reversed));
  return g;
}

final Map<String, _GnGeo> _gnCache = {};

class _GnPart {
  double x, y, vx, vy, l = 0, ml, r;
  Color c;
  _GnPart(this.x, this.y, this.vx, this.vy, this.ml, this.r, this.c);
}

class _GnPainter extends CustomPainter {
  final double t, p, yaw, pitch, zm, fl;
  final String shape, tint;
  final List<_GnPart> parts;
  final List<({double t0, Color col})> sw;
  _GnPainter(this.t, this.p, this.yaw, this.pitch, this.zm, this.fl, this.shape, this.tint, this.parts, this.sw);

  late double cy_, sy_, cp_, sp_, W, H, U;

  List<double> pr(double x, double y, double z) {
    final x1 = x * cy_ - z * sy_, z1 = x * sy_ + z * cy_;
    final y2 = y * cp_ + z1 * sp_, z2 = z1 * cp_ - y * sp_;
    final k = 6 / (6 + z2);
    return [W / 2 + x1 * k * U, H * .5 - y2 * k * U, x1, y2, z2, k];
  }

  void gem(List<Map<String, dynamic>> list, String sh, double cx, double cy, double cz, double sc, double st, double spin, Color tintC, double mix, double al) {
    final g = _gnCache.putIfAbsent(sh, () => _gnGeo(kGnSh[sh]!));
    final cs = math.cos(spin), sn = math.sin(spin);
    final P = [for (final v in g.v) pr(cx + (v[0] * cs + v[2] * sn) * sc, cy + v[1] * sc * st, cz + (-v[0] * sn + v[2] * cs) * sc)];
    final cen = pr(cx, cy, cz);
    final tc = Color.lerp(tintC, kGnGold, mix)!;
    const ll = .98;
    const L = [-.45 / ll, .75 / ll, -.5 / ll];
    final hl = math.sqrt(.45 * .45 + .75 * .75 + 1.5 * 1.5);
    final H0 = [-.45 / hl, .75 / hl, -1.5 / hl];
    for (var fi = 0; fi < g.f.length; fi++) {
      final f = g.f[fi];
      final a = P[f[0]], b = P[f[1]], c = P[f[2]];
      final ux = b[2] - a[2], uy = b[3] - a[3], uz = b[4] - a[4], wx = c[2] - a[2], wy = c[3] - a[3], wz = c[4] - a[4];
      var nx = uy * wz - uz * wy, ny = uz * wx - ux * wz, nz = ux * wy - uy * wx;
      final nl = math.sqrt(nx * nx + ny * ny + nz * nz);
      if (nl == 0) continue;
      nx /= nl;
      ny /= nl;
      nz /= nl;
      var mx = 0.0, my = 0.0, mz = 0.0, sx = 0.0, sy = 0.0;
      final pts = <Offset>[];
      for (final j in f) {
        final q = P[j];
        mx += q[2];
        my += q[3];
        mz += q[4];
        pts.add(Offset(q[0], q[1]));
        sx += q[0];
        sy += q[1];
      }
      mx /= f.length;
      my /= f.length;
      mz /= f.length;
      sx /= f.length;
      sy /= f.length;
      if (nx * (mx - cen[2]) + ny * (my - cen[3]) + nz * (mz - cen[4]) < 0) {
        nx = -nx;
        ny = -ny;
        nz = -nz;
      }
      final front = nz < 0;
      final diff = math.max(0.0, nx * L[0] + ny * L[1] + nz * L[2]);
      final spc = math.pow(math.max(0.0, nx * H0[0] + ny * H0[1] + nz * H0[2]), 22).toDouble();
      final fr = 1 - nz.abs();
      final flv = fl * (.4 + .6 * (((fi * 37) % 7) / 7));
      final s = .2 + .8 * diff;
      final add = 255 * (spc * .85 + flv * .5);
      final r = math.min(255, tc.red * s + add).toInt(), gg = math.min(255, tc.green * s + add).toInt(), bb = math.min(255, tc.blue * s + add).toInt();
      final alp = front ? (.2 + .32 * fr + .4 * spc + .25 * flv) : (.07 + .1 * fr);
      list.add({'k': 'f', 'pts': pts, 'z': mz, 'c': Color.fromRGBO(r, gg, bb, math.min(.95, alp * al)), 'front': front, 'sp': spc, 'x': sx, 'y': sy, 's': sc});
    }
  }

  void ring(List<Map<String, dynamic>> list, double y, double rad, Color col, double wid, double a) {
    final near = <Offset>[], far = <Offset>[];
    for (var i = 0; i <= 64; i++) {
      final an = i / 64 * math.pi * 2;
      final q = pr(math.cos(an) * rad, y, math.sin(an) * rad);
      (q[4] <= 0 ? near : far).add(Offset(q[0], q[1]));
    }
    list.add({'k': 'l', 'pts': far, 'z': 9.0, 'col': col.withOpacity(a), 'w': wid});
    list.add({'k': 'l', 'pts': near, 'z': -9.0, 'col': col.withOpacity(a), 'w': wid});
  }

  @override
  void paint(Canvas c, Size size) {
    W = size.width;
    H = size.height;
    U = math.min(W * .26, H * .21) * zm;
    cy_ = math.cos(yaw);
    sy_ = math.sin(yaw);
    cp_ = math.cos(pitch);
    sp_ = math.sin(pitch);
    c.drawRect(Offset.zero & size, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF070A12), Color(0xFF0C1220)]).createShader(Offset.zero & size));
    final tn = kGnT[tint]!.$2;
    final gm = .6 * math.max(0.0, math.min(1.0, (p - .92) / .08));
    final tg = Color.lerp(tn, kGnGold, gm)!;
    final rnd = math.Random(7);
    for (var i = 0; i < 70; i++) {
      final a = .2 + .35 * (.5 + .5 * math.sin(t * .8 + rnd.nextDouble() * 6.28));
      c.drawRect(Rect.fromLTWH(rnd.nextDouble() * W, rnd.nextDouble() * H, rnd.nextDouble() < .15 ? 2 : 1, 1.5), Paint()..color = const Color(0xFFD2DCF0).withOpacity(a));
    }
    final cen = pr(0, 0, 0), fp = pr(0, -1.95, 0);
    c.drawCircle(Offset(cen[0], cen[1]), U * (1.7 + p * .8), Paint()..shader = RadialGradient(colors: [tg.withOpacity(.1 + .14 * p + fl * .14), tg.withOpacity(0)]).createShader(Rect.fromCircle(center: Offset(cen[0], cen[1]), radius: U * (1.7 + p * .8))));
    c.save();
    c.translate(fp[0], fp[1]);
    c.scale(1, .3);
    c.drawCircle(Offset.zero, U * 2.4, Paint()..shader = RadialGradient(colors: [tg.withOpacity(.2 + .2 * p), tg.withOpacity(0)]).createShader(Rect.fromCircle(center: Offset.zero, radius: U * 2.4)));
    c.restore();
    if (p >= .5) {
      final bw = U * (.35 + .25 * p);
      c.drawRect(Rect.fromLTRB(cen[0] - bw, 0, cen[0] + bw, fp[1]), Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [tg.withOpacity(0), tg.withOpacity(.07 * p + gm * .06), tg.withOpacity(0)]).createShader(Rect.fromLTRB(0, 0, W, fp[1])));
    }
    for (var ri = 0; ri < 3; ri++) {
      final rr = [1.2, 1.9, 2.6][ri];
      final path = Path();
      for (var j = 0; j <= 64; j++) {
        final an = j / 64 * math.pi * 2;
        final q = pr(math.cos(an) * rr, -1.95, math.sin(an) * rr);
        j == 0 ? path.moveTo(q[0], q[1]) : path.lineTo(q[0], q[1]);
      }
      c.drawPath(path, Paint()..color = tg.withOpacity((.14 + .1 * p) * (1 - ri * .25))..style = PaintingStyle.stroke..strokeWidth = 1);
    }
    for (final w in sw) {
      final k = (t - w.t0) / 1.8;
      if (k < 0 || k > 1) continue;
      final rr = .6 + k * 3.6;
      final path = Path();
      for (var j = 0; j <= 64; j++) {
        final an = j / 64 * math.pi * 2;
        final q = pr(math.cos(an) * rr, -1.95, math.sin(an) * rr);
        j == 0 ? path.moveTo(q[0], q[1]) : path.lineTo(q[0], q[1]);
      }
      c.drawPath(path, Paint()..color = w.col.withOpacity(.6 * (1 - k))..style = PaintingStyle.stroke..strokeWidth = 2.5 * (1 - k) + .5);
    }
    // crystal
    final list = <Map<String, dynamic>>[];
    final breath = 1 + .015 * math.sin(t * 1.6);
    final sc = (.52 + .5 * p) * breath, st = 1 + .16 * p;
    list.add({'k': 'g', 'z': 0.0, 'r': sc});
    gem(list, shape, 0, 0, 0, sc, st, 0, tn, gm, 1);
    gem(list, 'oktaedr', 0, 0, 0, sc * (.16 + .3 * p), 1, -t * .9, Color.lerp(tn, Colors.white, .45)!, gm, .3 + .6 * p);
    const ths = [.25, .5, .75, 1.0];
    for (var i = 0; i < 4; i++) {
      final ps = math.max(0.0, math.min(1.0, (p - ths[i] + .02) / .05));
      if (ps <= 0) continue;
      final an = t * .55 * (i.isOdd ? -1 : 1) + i * 1.57, rad = 1.85 + .12 * i;
      gem(list, i.isOdd ? 'oktaedr' : 'brilliant', math.cos(an) * rad, .45 * math.sin(t * .8 + i * 2) + (i - 1.5) * .18, math.sin(an) * rad, .17 * ps, 1, t * 1.3 + i, tn, gm, .9);
    }
    if (gm > 0) {
      final ps5 = gm / .6, cyc = 1.15 * (.52 + .5 * p) * (1 + .16 * p) + .5;
      gem(list, 'obelisk', 0, cyc + .08 * math.sin(t * 2), 0, .3 * ps5, 1, t * 1.1, tn, .6, .95);
      final an4 = -t * .8;
      gem(list, 'oktaedr', math.cos(an4) * 1.4, .9, math.sin(an4) * 1.4, .15 * ps5, 1, t * 2, tn, .6, .95);
      ring(list, .1, 1.75, kGnGold, 2, .5 * ps5);
      ring(list, .1, 1.95, kGnGold, 1, .28 * ps5);
    }
    list.sort((a, b) => (b['z'] as double).compareTo(a['z'] as double));
    for (final it in list) {
      if (it['k'] == 'f') {
        final pts = it['pts'] as List<Offset>;
        final path = Path()..addPolygon(pts, true);
        c.drawPath(path, Paint()..color = it['c'] as Color);
        c.drawPath(path, Paint()..color = Colors.white.withOpacity(it['front'] == true ? .24 : .07)..style = PaintingStyle.stroke..strokeWidth = 1);
        if (it['front'] == true && (it['sp'] as double) > .5) {
          final fs = U * .1 * (it['sp'] as double) * ((it['s'] as double) > .3 ? 1 : .4);
          final x = it['x'] as double, y = it['y'] as double;
          final pp = Paint()..color = Colors.white.withOpacity(.5 * (it['sp'] as double))..strokeWidth = 1.2;
          c.drawLine(Offset(x - fs, y), Offset(x + fs, y), pp);
          c.drawLine(Offset(x, y - fs), Offset(x, y + fs), pp);
        }
      } else if (it['k'] == 'g') {
        final gr = U * (it['r'] as double) * 1.1;
        c.drawCircle(Offset(cen[0], cen[1]), gr, Paint()..shader = RadialGradient(colors: [Colors.white.withOpacity(.16 + .34 * p + fl * .3), tg.withOpacity(.1 + .14 * p), tg.withOpacity(0)], stops: const [0, .4, 1]).createShader(Rect.fromCircle(center: Offset(cen[0], cen[1]), radius: gr)));
      } else if (it['k'] == 'l') {
        final pts = it['pts'] as List<Offset>;
        if (pts.length > 1) c.drawPath(Path()..addPolygon(pts, false), Paint()..color = it['col'] as Color..style = PaintingStyle.stroke..strokeWidth = it['w'] as double);
      }
    }
    if (gm > 0) {
      for (var i = 0; i < 16; i++) {
        final ra = i / 16 * 6.283 + t * .15, r1 = U * 1.9, r2 = U * (2.4 + .5 * math.sin(t * 2 + i));
        final a = Offset(cen[0] + math.cos(ra) * r1, cen[1] + math.sin(ra) * r1 * .8), b = Offset(cen[0] + math.cos(ra) * r2, cen[1] + math.sin(ra) * r2 * .8);
        c.drawLine(a, b, Paint()..shader = LinearGradient(colors: [kGnGold.withOpacity(.35 * gm / .6), kGnGold.withOpacity(0)]).createShader(Rect.fromPoints(a, b))..strokeWidth = 1);
      }
    }
    for (final q in parts) {
      final qa = 1 - q.l / q.ml;
      c.drawCircle(Offset(q.x, q.y), q.r * (.5 + qa), Paint()..color = q.c.withOpacity(qa * .9));
    }
    final rr = math.Random(3);
    for (var i = 0; i < 26; i++) {
      final ma = .15 + .25 * (.5 + .5 * math.sin(t + i));
      c.drawCircle(Offset(rr.nextDouble() * W + math.sin(t * .4 + i) * 8, ((rr.nextDouble() - t * (.01 + rr.nextDouble() * .03) * 3) % 1.0) * H), .6 + rr.nextDouble() * 1.4, Paint()..color = tg.withOpacity(ma));
    }
  }

  @override
  bool shouldRepaint(covariant _GnPainter o) => true;
}

class GenesisTab extends StatefulWidget {
  final ShellApi api;
  const GenesisTab({super.key, required this.api});
  @override
  State<GenesisTab> createState() => _GenesisTabState();
}

class _GenesisTabState extends State<GenesisTab> with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(vsync: this, duration: const Duration(seconds: 3600))..repeat();
  double t = 0, dp = 0, tp = 0, yaw = .6, pitch = .28, vel = 0, zm = 1, fl = 0, _last = 0, _zs = 1;
  final List<_GnPart> parts = [];
  final List<({double t0, Color col})> sw = [];
  final amt = TextEditingController();
  String banner = '';
  double _bannerT = 0;
  final rnd = math.Random();
  Size _sz = const Size(360, 380);

  Profile get p => app.profile!;
  Map<String, dynamic> _g() {
    final g = p.mp('gen');
    if (!kGnSh.containsKey(g['s'])) g['s'] = 'brilliant';
    if (!kGnT.containsKey(g['t'])) g['t'] = 'silver';
    mpG(g, 'ms');
    return g;
  }

  Map<String, dynamic> mpG(Map<String, dynamic> m, String k) {
    final v = m[k];
    if (v is Map<String, dynamic>) return v;
    final n = <String, dynamic>{};
    m[k] = n;
    return n;
  }

  Goal? _goal() {
    final gs = p.goals;
    final g = _g();
    for (final x in gs) {
      if (x.id == g['g']) return x;
    }
    return gs.isNotEmpty ? gs.first : null;
  }

  double _pct(Goal? g) => g != null && g.target > 0 ? math.max(0.0, math.min(1.0, g.saved / g.target)) : 0;

  @override
  void initState() {
    super.initState();
    _ac.addListener(_tick);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync(true));
  }

  @override
  void dispose() {
    _ac.dispose();
    amt.dispose();
    super.dispose();
  }

  void _sync(bool first) {
    final g = _goal();
    if (g == null) {
      tp = 0;
      return;
    }
    final pc = _pct(g);
    var mc = 0;
    for (var i = 0; i < kGnM.length; i++) {
      if (pc >= kGnM[i].$1 - 1e-9) mc = i + 1;
    }
    tp = pc;
    final gn = _g();
    final ms = mpG(gn, 'ms');
    final st = ms[g.id];
    if (st == null) {
      ms[g.id] = mc;
      app.saveProfile();
    } else if (mc > (st as num)) {
      ms[g.id] = mc;
      app.saveProfile();
      Future<void>.delayed(Duration(milliseconds: first ? 1100 : 250), () {
        if (mounted) _mile(mc - 1);
      });
    } else if (mc < st) {
      ms[g.id] = mc;
      app.saveProfile();
    }
  }

  void _mile(int mi) {
    final m = kGnM[mi];
    final done = mi == 3;
    final col = done ? kGnGold : kGnT[_g()['t']]!.$2;
    final n = [40, 70, 100, 170][mi];
    final sp = [180, 230, 280, 360][mi].toDouble();
    final cx = _sz.width / 2, cy = _sz.height / 2;
    for (var i = 0; i < n; i++) {
      final a = rnd.nextDouble() * 6.283, s = (.3 + rnd.nextDouble()) * sp;
      parts.add(_GnPart(cx, cy, math.cos(a) * s, math.sin(a) * s - 30, 1.2 + rnd.nextDouble() * 1.2, 1 + rnd.nextDouble() * 2, col));
    }
    if (parts.length > 420) parts.removeRange(0, parts.length - 420);
    for (var k = 0; k < [1, 1, 2, 3][mi]; k++) {
      sw.add((t0: t + k * .35, col: col));
    }
    fl = [.6, .8, 1, 1.4][mi].toDouble();
    banner = '${m.$2} · ${m.$3}';
    _bannerT = 3;
    toast(context, 'Genesis · ${m.$2}: ${m.$3}');
  }

  void _tick() {
    final now = _ac.value * 3600.0;
    var dt = now - _last;
    if (dt < 0) dt += 3600;
    _last = now;
    dt = math.min(.05, dt);
    t += dt;
    yaw += (.22 + vel) * dt;
    vel *= math.exp(-dt * 2.5);
    dp += (tp - dp) * math.min(1.0, dt * 1.8);
    if ((tp - dp).abs() < .0005) dp = tp;
    fl = math.max(0, fl - dt * .9);
    _bannerT = math.max(0, _bannerT - dt);
    for (final q in parts) {
      q.x += q.vx * dt;
      q.y += q.vy * dt;
      q.vy += 60 * dt;
      q.vx *= .985;
      q.l += dt;
    }
    parts.removeWhere((q) => q.l >= q.ml);
    sw.removeWhere((w) => t - w.t0 > 1.8);
    _sync(false);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final g = _goal();
    final gn = _g();
    final pc = _pct(g);
    final gs = p.goals;
    final left = g == null ? 0.0 : math.max(0.0, g.target - g.saved);
    (double, String, String)? nx;
    for (final m in kGnM) {
      if (pc < m.$1 - 1e-9) {
        nx = m;
        break;
      }
    }
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
      const Text('VAULT GENESIS', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const Text('Every Goal Begins Somewhere', style: TextStyle(color: C.dim, fontSize: 13.5)),
      const SizedBox(height: 12),
      ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 380,
          child: LayoutBuilder(builder: (ctx, bc) {
            _sz = Size(bc.maxWidth, 380);
            return Stack(fit: StackFit.expand, children: [
              GestureDetector(
                onScaleStart: (d) => _zs = zm,
                onScaleUpdate: (d) {
                  if (d.pointerCount >= 2) {
                    zm = (_zs * d.scale).clamp(.6, 1.8);
                  } else {
                    yaw += d.focalPointDelta.dx * .01;
                    pitch = (pitch + d.focalPointDelta.dy * .006).clamp(-.3, 1.1);
                    vel = (d.focalPointDelta.dx * .06 * 60 / 60).clamp(-3.0, 3.0);
                  }
                },
                child: CustomPaint(painter: _GnPainter(t, dp, yaw, pitch, zm, fl, '${gn['s']}', '${gn['t']}', parts, sw)),
              ),
              Positioned(
                left: 14,
                top: 12,
                right: 60,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('GENESIS CORE', style: TextStyle(color: C.dim, fontSize: 10.5, letterSpacing: 1.6, fontWeight: FontWeight.w700)),
                  Text('${(dp * 100).round()}%', style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800)),
                  Text(g?.name ?? "Maqsad yo'q", style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(g == null ? "Kristalni o'stirish uchun maqsad qo'shing" : pc >= 1 ? "Maqsadga erishildi · yakuniy shakl" : '${grp(g.saved)} / ${grp(g.target)} ${curUnit()}', style: const TextStyle(color: Color(0xFFA9B1C0), fontSize: 12.5)),
                ]),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Column(children: [
                  _gb('↺', () => setState(() {
                        yaw = .6;
                        pitch = .28;
                        vel = 0;
                        zm = 1;
                      })),
                  _gb('▶', () => setState(() {
                        yaw = .6;
                        pitch = .28;
                        zm = 1;
                        vel = 2.2;
                        dp = 0;
                      })),
                  _gb('+', () => setState(() => zm = math.min(1.8, zm * 1.2))),
                  _gb('−', () => setState(() => zm = math.max(.6, zm / 1.2))),
                ]),
              ),
              if (_bannerT > 0) Positioned(left: 0, right: 0, bottom: 20, child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(14), border: Border.all(color: kGnGold.withOpacity(.5))), child: Text(banner, style: const TextStyle(fontWeight: FontWeight.w800))))),
            ]);
          }),
        ),
      ),
      if (gs.length > 1) ...[
        const SizedBox(height: 10),
        Wrap(spacing: 8, children: [
          for (final x in gs)
            ChoiceChip(
              label: Text(x.name),
              selected: g != null && x.id == g.id,
              onSelected: (_) {
                gn['g'] = x.id;
                app.saveProfile();
                dp = 0;
                _sync(false);
              },
            ),
        ]),
      ],
      const SizedBox(height: 14),
      uCard('Jonli holat', children: [
        if (g == null) ...[uSmall("Genesis krisetali maqsadingizga bog'langan. Avval birinchi maqsadingizni qo'shing: kristall u bilan birga o'sadi."), uBtn("Maqsad qo'shish", () => widget.api.show('goals'))] else ...[
          uBar(pc, C.accent),
          const SizedBox(height: 8),
          URow(title: "Yig'ilgan", amount: '${grp(g.saved)} ${curUnit()}'),
          URow(title: 'Maqsad', amount: '${grp(g.target)} ${curUnit()}'),
          URow(title: 'Qoldi', amount: '${grp(left)} ${curUnit()}'),
          URow(title: 'Keyingi bosqich', amount: nx != null ? '${nx.$2}\n${grp(math.max(0.0, g.target * nx.$1 - g.saved))} ${curUnit()}' : 'Yakunlandi'),
          Row(children: [
            for (final m in kGnM)
              Expanded(child: Column(children: [Icon(pc >= m.$1 - 1e-9 ? Icons.diamond_rounded : Icons.diamond_outlined, size: 18, color: pc >= m.$1 - 1e-9 ? kGnGold : C.mute), Text(m.$2, style: TextStyle(fontSize: 11.5, color: pc >= m.$1 - 1e-9 ? C.ink : C.dim))])),
          ]),
        ],
      ]),
      if (g != null)
        uCard("Jamg'armaga qo'shish", children: [
          Row(children: [
            Expanded(child: uField(amt, 'Summa', num: true)),
            const SizedBox(width: 8),
            SizedBox(
              width: 110,
              child: uBtn("Qo'shish", () async {
                final v = parseAmount(amt.text);
                if (v == null || v <= 0) return toast(context, "Summani to'g'ri kiriting");
                g.saved = fixAmt(g.saved + v);
                amt.clear();
                await app.saveProfile();
                _sync(false);
                if (mounted) {
                  setState(() {});
                  toast(context, "Jamg'armaga qo'shildi");
                }
              }),
            ),
          ]),
        ]),
      uCard('Shaxsiy kristall', children: [
        Wrap(spacing: 8, children: [
          for (final k in kGnSh.keys)
            ChoiceChip(label: Text(kGnN[k]!), selected: gn['s'] == k, onSelected: (_) {
              gn['s'] = k;
              fl = .6;
              app.saveProfile();
            }),
        ]),
        const SizedBox(height: 10),
        const Text('Rang', style: TextStyle(color: C.dim, fontWeight: FontWeight.w700, fontSize: 12.5)),
        const SizedBox(height: 6),
        Wrap(spacing: 8, children: [
          for (final k in kGnT.keys)
            ChoiceChip(label: Text(kGnT[k]!.$1), selected: gn['t'] == k, onSelected: (_) {
              gn['t'] = k;
              fl = .6;
              app.saveProfile();
            }),
        ]),
      ]),
      const Center(child: Padding(padding: EdgeInsets.only(top: 6), child: Text('VAULT GENESIS · FROM EIGHTEEN.', style: TextStyle(color: C.mute, fontSize: 11, letterSpacing: 1.4)))),
    ]);
  }

  Widget _gb(String l, VoidCallback f) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: GestureDetector(onTap: f, child: Container(width: 36, height: 36, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10), border: Border.all(color: C.line)), child: Text(l, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)))),
      );
}

/* ====================================================================== */
/*  VAULT NEXUS (Max Exclusive): living financial core, CPU-rendered 3D    */
/* ====================================================================== */
class _NxPulse {
  double x, y, z, t = 0, s;
  _NxPulse(this.x, this.y, this.z, this.s);
}

class _NxPart {
  double x, y, z, vx, vy, vz, life;
  bool inc;
  _NxPart(this.x, this.y, this.z, this.vx, this.vy, this.vz, this.life, this.inc);
}

class _NxPainter extends CustomPainter {
  final double t, yaw, pitch, zoom, kick, amp, fr, sc, flI, flO, ringSpeed;
  final List<_NxPulse> pulses;
  final List<_NxPart> parts;
  final double stress;
  _NxPainter(this.t, this.yaw, this.pitch, this.zoom, this.kick, this.amp, this.fr, this.sc, this.flI, this.flO, this.ringSpeed, this.pulses, this.parts, this.stress);

  double radius(double x, double y, double z) {
    var r = 1 + amp * (math.sin(x * fr * 2.1 + t * 1.1) * math.sin(y * fr * 1.7 - t * .9) + .6 * math.sin(z * fr * 2.9 + x * fr + t * 1.4) * math.cos(y * fr * 2.3 + t * .7));
    for (final p in pulses) {
      final d = math.acos((x * p.x + y * p.y + z * p.z).clamp(-1.0, 1.0));
      final w = d - p.t * 2.4;
      r += p.s * math.exp(-w * w * 5 - p.t * 1.1) * (1 + .4 * math.sin(d * 12 - p.t * 8));
    }
    return r;
  }

  // world -> screen (rotate yaw around Y, pitch around X, perspective)
  (double, double, double) proj(double x, double y, double z, Size s, double scale) {
    final cy = math.cos(yaw), sy = math.sin(yaw);
    final x1 = x * cy + z * sy, z1 = -x * sy + z * cy;
    final cp = math.cos(pitch), sp = math.sin(pitch);
    final y2 = y * cp - z1 * sp, z2 = y * sp + z1 * cp;
    final k = 6.5 / (6.5 - z2 * .9) * scale;
    return (s.width / 2 + x1 * k, s.height * .5 - y2 * k, z2);
  }

  @override
  void paint(Canvas c, Size size) {
    c.drawRect(Offset.zero & size, Paint()..shader = const RadialGradient(colors: [Color(0xFF0B1020), Color(0xFF020306)]).createShader(Offset.zero & size));
    final scale = math.min(size.width, size.height) * .27 * zoom * sc * (1 + kick * .07);
    // floor ripple rings
    for (var i = 0; i < 9; i++) {
      final rr = .8 + i * .45;
      final pts = <Offset>[];
      for (var a = 0; a <= 48; a++) {
        final th = a / 48 * math.pi * 2;
        var h = .025 * math.sin(rr * math.cos(th) * 1.1 + t * .8);
        for (final p in pulses) {
          h += p.s * .9 * math.sin(rr * 2.6 - p.t * 7) * math.exp(-rr * .35 - p.t * 1.1) * math.min(1.0, p.t * 4);
        }
        final q = proj(rr * math.cos(th) * 1.4, -1.9 + h, rr * math.sin(th) * 1.4, size, scale);
        pts.add(Offset(q.$1, q.$2));
      }
      final path = Path()..addPolygon(pts, true);
      c.drawPath(path, Paint()..color = const Color(0xFF6F9BFF).withOpacity(.09 + flI * .06 + flO * .04 * (i % 2))..style = PaintingStyle.stroke..strokeWidth = 1);
    }
    // back half of rings
    _rings(c, size, scale, back: true);
    // sphere mesh
    const nu = 36, nv = 22;
    final vs = List.generate(nv + 1, (j) => List<(double, double, double, double, double, double)>.filled(nu + 1, (0, 0, 0, 0, 0, 0)));
    for (var j = 0; j <= nv; j++) {
      final ph = math.pi * j / nv;
      for (var i = 0; i <= nu; i++) {
        final th = math.pi * 2 * i / nu;
        final x = math.sin(ph) * math.cos(th), y = math.cos(ph), z = math.sin(ph) * math.sin(th);
        final r = radius(x, y, z);
        final p = proj(x * r, y * r + .12 * math.sin(t * .9) * .5, z * r, size, scale);
        vs[j][i] = (p.$1, p.$2, p.$3, x * r, y * r, z * r);
      }
    }
    final quads = <({List<Offset> p, double z, double sh})>[];
    for (var j = 0; j < nv; j++) {
      for (var i = 0; i < nu; i++) {
        final a = vs[j][i], b = vs[j][i + 1], d = vs[j + 1][i], e = vs[j + 1][i + 1];
        final ux = b.$4 - a.$4, uy = b.$5 - a.$5, uz = b.$6 - a.$6, vx = d.$4 - a.$4, vy = d.$5 - a.$5, vz = d.$6 - a.$6;
        var nx = uy * vz - uz * vy, ny = uz * vx - ux * vz, nz = ux * vy - uy * vx;
        final l = math.sqrt(nx * nx + ny * ny + nz * nz) + 1e-9;
        nx /= l;
        ny /= l;
        nz /= l;
        // light from upper-left-front in world space + environment-like rim
        final cy = math.cos(yaw), sy = math.sin(yaw);
        final wx = nx * cy + nz * sy, wz = -nx * sy + nz * cy;
        final cp = math.cos(pitch), sp = math.sin(pitch);
        final wy = ny * cp - wz * sp, wz2 = ny * sp + wz * cp;
        if (wz2 < -.05) continue; // back-face
        final lam = (-.35 * wx + .55 * wy + .75 * wz2).clamp(0.0, 1.0);
        final rim = math.pow(1 - wz2.clamp(0.0, 1.0), 2.5).toDouble();
        final refl = (math.pow(((-.3 * wx + .6 * wy + .74 * wz2) * 1.0).clamp(0.0, 1.0), 18)).toDouble();
        quads.add((p: [Offset(a.$1, a.$2), Offset(b.$1, b.$2), Offset(e.$1, e.$2), Offset(d.$1, d.$2)], z: (a.$3 + e.$3) / 2, sh: (.18 + lam * .55 + refl * .5 + rim * .25).clamp(0.0, 1.0)));
      }
    }
    quads.sort((a, b) => a.z.compareTo(b.z));
    for (final q in quads) {
      final base = Color.lerp(const Color(0xFF1A2236), const Color(0xFFEAF0FA), q.sh)!;
      final tint = stress > 1 ? Color.lerp(base, const Color(0xFF9A2A2A), .22 * (stress - 1).clamp(0, 1))! : stress > .8 ? Color.lerp(base, const Color(0xFFB08A2A), .12)! : Color.lerp(base, const Color(0xFF2A4C9A), .12)!;
      final path = Path()..addPolygon(q.p, true);
      c.drawPath(path, Paint()..color = tint..style = PaintingStyle.fill);
      c.drawPath(path, Paint()..color = tint..style = PaintingStyle.stroke..strokeWidth = .6);
    }
    _rings(c, size, scale, back: false);
    // particles
    for (final p in parts) {
      if (p.life <= 0) continue;
      final q = proj(p.x, p.y, p.z, size, scale);
      final a = p.life.clamp(0.0, 1.0);
      c.drawCircle(Offset(q.$1, q.$2), 2.6, Paint()..color = (p.inc ? const Color(0xFF9ED1FF) : const Color(0xFFFF5C4D)).withOpacity(a)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    }
  }

  void _rings(Canvas c, Size size, double scale, {required bool back}) {
    final specs = [(1.78, 2.2, 1.2), (2.12, 1.4, 1.7)];
    for (var k = 0; k < specs.length; k++) {
      final rot = t * ringSpeed * (k == 0 ? 1 : -.6);
      final pts = <(Offset, double)>[];
      for (var a = 0; a <= 90; a++) {
        final th = a / 90 * math.pi * 2 + rot;
        var x = specs[k].$1 * math.cos(th), y = 0.0, z = specs[k].$1 * math.sin(th);
        final tx = specs[k].$3;
        final y1 = y * math.cos(tx) - z * math.sin(tx), z1 = y * math.sin(tx) + z * math.cos(tx);
        y = y1;
        z = z1;
        final q = proj(x, y, z, size, scale);
        pts.add((Offset(q.$1, q.$2), q.$3));
      }
      for (var a = 0; a < pts.length - 1; a++) {
        final isBack = pts[a].$2 < 0;
        if (isBack != back) continue;
        c.drawLine(pts[a].$1, pts[a + 1].$1, Paint()..color = const Color(0xFFE6ECF8).withOpacity(back ? .35 : .9)..strokeWidth = specs[k].$2..strokeCap = StrokeCap.round);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NxPainter o) => true;
}

class NexusTab extends StatefulWidget {
  final ShellApi api;
  const NexusTab({super.key, required this.api});
  @override
  State<NexusTab> createState() => _NexusTabState();
}

class _NexusTabState extends State<NexusTab> with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(vsync: this, duration: const Duration(seconds: 3600))..repeat();
  double t = 0, yaw = .5, pitch = .14, vel = 0, zoom = 1, kick = 0, flI = 0, flO = 0, bal = 0;
  double amp = .07, fr = 2, sc = 1;
  bool auto = true;
  ({double y, double p})? go;
  final List<_NxPulse> pulses = [];
  final List<_NxPart> parts = [];
  double _last = 0, _scaleStartZoom = 1;
  int _sigN = -1;
  String link = '';
  final amt = TextEditingController();
  final rnd = math.Random();

  ({double i, double o, double bal, double r, double sv}) _stats() {
    final s = app.sums(monthKeyOf(DateTime.now()));
    final r = s.i > 0 ? s.o / s.i : (s.o > 0 ? 1.5 : 0.0);
    return (i: s.i, o: s.o, bal: s.i - s.o, r: r, sv: s.i > 0 ? math.max(0.0, math.min(1.0, (s.i - s.o) / s.i)) : 0.0);
  }

  @override
  void initState() {
    super.initState();
    _ac.addListener(_tick);
    _sigN = app.txs.length;
  }

  @override
  void dispose() {
    _ac.dispose();
    amt.dispose();
    super.dispose();
  }

  void _pulse(String type, double a) {
    final s = _stats();
    final base = math.max(math.max(s.i, s.o), 1.0);
    final k = math.min(1.0, .3 + .7 * math.min(1.0, a / (base * .25)));
    final inc = type == 'in';
    var x = rnd.nextDouble() * 2 - 1, y = rnd.nextDouble() * 2 - 1, z = rnd.nextDouble() * 2 - 1;
    final l = math.sqrt(x * x + y * y + z * z);
    x /= l;
    y /= l;
    z /= l;
    pulses.add(_NxPulse(x, y, z, (inc ? .2 : -.17) * (.6 + k)));
    if (pulses.length > 4) pulses.removeAt(0);
    kick += inc ? k : -k;
    if (inc) {
      flI = 1.6 * (.5 + k);
    } else {
      flO = 1.6 * (.5 + k);
    }
    final n = (40 + 90 * k).round();
    for (var i = 0; i < n; i++) {
      final u = rnd.nextDouble() * 6.283, w = rnd.nextDouble() * 2 - 1, q = math.sqrt(1 - w * w);
      final d = (q * math.cos(u), w, q * math.sin(u));
      final v = inc ? -(1.4 + rnd.nextDouble() * 1.4) : (1.2 + rnd.nextDouble() * 1.8);
      final rr = inc ? 3.2 + rnd.nextDouble() * 1.2 : 1.08;
      parts.add(_NxPart(d.$1 * rr, d.$2 * rr, d.$3 * rr, d.$1 * v, d.$2 * v, d.$3 * v, 1.4 + rnd.nextDouble() * .6, inc));
    }
    if (parts.length > 420) parts.removeRange(0, parts.length - 420);
  }

  void _tick() {
    final now = _ac.value * 3600.0;
    var dt = now - _last;
    if (dt < 0) dt += 3600;
    _last = now;
    dt = math.min(.05, dt);
    t += dt;
    final s = _stats();
    final r = math.min(1.6, s.r);
    final gAmp = .03 + .14 * math.min(1.0, r), gFr = 1.5 + 2.4 * r, gSc = .84 + .2 * s.sv;
    final k = 1 - math.exp(-dt * 2.4);
    amp += (gAmp - amp) * k;
    fr += (gFr - fr) * k;
    sc += (gSc - sc) * k;
    for (final p in pulses) {
      p.t += dt;
    }
    pulses.removeWhere((p) => p.t >= 3);
    kick *= math.exp(-dt * 3.2);
    flI *= math.exp(-dt * 2.6);
    flO *= math.exp(-dt * 2.6);
    for (final p in parts) {
      if (p.life <= 0) continue;
      p.life -= dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.z += p.vz * dt;
    }
    parts.removeWhere((p) => p.life <= 0);
    if (go != null) {
      final d = ((go!.y - yaw + math.pi) % (2 * math.pi) + 2 * math.pi) % (2 * math.pi) - math.pi;
      final kk = 1 - math.exp(-dt * 4);
      yaw += d * kk;
      pitch += (go!.p - pitch) * kk;
      if (d.abs() < .01 && (go!.p - pitch).abs() < .01) go = null;
    } else {
      yaw += vel * dt;
      vel *= math.exp(-dt * 2.5);
      if (auto) yaw += dt * .14;
    }
    pitch = pitch.clamp(-.2, 1.35);
    bal += (s.bal - bal) * (1 - math.exp(-dt * 3));
    // react to new transactions
    if (app.txs.length != _sigN) {
      final added = app.txs.length - _sigN;
      if (added > 0) {
        final nw = app.txs.toList()..sort((a, b) => a.ts.compareTo(b.ts));
        for (final x in nw.skip(math.max(0, nw.length - math.min(3, added)))) {
          _pulse(x.t, x.a);
          link = "So'nggi: ${x.t == 'in' ? 'kirim +' : 'chiqim −'}${eShort(x.a)} ${app.cur}: yadro javob berdi";
        }
      }
      _sigN = app.txs.length;
    }
    if (mounted) setState(() {});
  }

  void _msg(String m) => toast(context, m);

  @override
  Widget build(BuildContext context) {
    final p = app.profile!;
    if (!p.isNexus) {
      return ListView(padding: const EdgeInsets.all(16), children: [
        const Text('VAULT NEXUS', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const Text('Max Exclusive', style: TextStyle(color: C.dim)),
        const SizedBox(height: 16),
        PrimaryButton(label: "Max tarifini ko'rish", onTap: () => widget.api.show('plans')),
      ]);
    }
    final s = _stats();
    final sub = s.i + s.o == 0 ? "Hali operatsiya yo'q: yadro tinch" : s.r > 1 ? 'Xarajat kirimdan oshdi: yadro bezovta' : s.r > .8 ? 'Xarajat yuqori: yadro tebranmoqda' : 'Barqaror holat: yadro silliq';
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
      const Text('VAULT NEXUS', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const Text('Max Exclusive', style: TextStyle(color: C.dim, fontSize: 13.5)),
      const SizedBox(height: 12),
      ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 380,
          child: Stack(fit: StackFit.expand, children: [
            GestureDetector(
              onScaleStart: (d) {
                _scaleStartZoom = zoom;
                vel = 0;
                go = null;
              },
              onScaleUpdate: (d) {
                if (d.pointerCount >= 2) {
                  zoom = (_scaleStartZoom * d.scale).clamp(.6, 2.2);
                } else {
                  yaw -= d.focalPointDelta.dx * .007;
                  pitch += d.focalPointDelta.dy * .005;
                  vel = (-d.focalPointDelta.dx * .007 * 60).clamp(-3.0, 3.0);
                }
              },
              child: CustomPaint(painter: _NxPainter(t, yaw, pitch, zoom, kick, amp, fr, sc, flI, flO, .25 + .5 * math.min(1.5, s.r), pulses, parts, s.r)),
            ),
            Positioned(
              left: 14,
              top: 12,
              right: 14,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${monthKeyOf(DateTime.now())} · jonli', style: const TextStyle(color: C.dim, fontSize: 11.5)),
                Text('${eShort(bal)} ${app.cur}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                Text(sub, style: const TextStyle(color: Color(0xFFA9B1C0), fontSize: 12.5)),
              ]),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: Wrap(spacing: 6, children: [
                _b('Old', () => setState(() {
                      go = (y: 0, p: .14);
                      auto = false;
                    })),
                _b('Tepa', () => setState(() {
                      go = (y: yaw, p: 1.3);
                      auto = false;
                    })),
                _b('Yon', () => setState(() {
                      go = (y: math.pi / 2, p: .1);
                      auto = false;
                    })),
                _b(auto ? 'Aylanish ✓' : 'Aylanish', () => setState(() => auto = !auto)),
                _b('＋', () => setState(() => zoom = math.min(2.2, zoom * 1.25))),
                _b('－', () => setState(() => zoom = math.max(.6, zoom / 1.25))),
              ]),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      Row(children: [_kp('Kirim', eShort(s.i)), _kp('Chiqim', eShort(s.o)), _kp("Jamg'arma", '${(s.sv * 100).round()}%')]),
      if (link.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(link, style: const TextStyle(color: C.dim, fontSize: 12.5))),
      const SizedBox(height: 12),
      uCard('Tez operatsiya', children: [
        uSmall("Summani kiriting va yadroga kirim yoki chiqim yuboring: u haqiqiy yozuv sifatida saqlanadi."),
        uField(amt, 'Summa, masalan 45000', num: true),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: uBtn('Kirim +', () => _quick('in'))),
          const SizedBox(width: 8),
          Expanded(child: uBtn('Chiqim −', () => _quick('out'), ghost: true)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: TextButton(onPressed: () => _pulse('in', _stats().i * .12 + 1e6), child: const Text('Namuna: kirim to\'lqini'))),
          Expanded(child: TextButton(onPressed: () => _pulse('out', _stats().i * .1 + 1e6), child: const Text('Namuna: chiqim to\'lqini'))),
        ]),
      ]),
    ]);
  }

  Future<void> _quick(String type) async {
    final v = parseAmount(amt.text);
    if (v == null || v <= 0) return _msg('Summani kiriting, masalan 45000.');
    final a = fixAmt(v);
    await app.addTx(Tx(id: newId(), t: type, a: a, c: type == 'in' ? catsOf('in').last.id : catsOf('out').last.id, n: 'Nexus', d: todayStr(), ts: DateTime.now().millisecondsSinceEpoch));
    amt.clear();
    if (mounted) limitCheck(context);
  }

  Widget _b(String l, VoidCallback f) => GestureDetector(
        onTap: f,
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10), border: Border.all(color: C.line)), child: Text(l, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
      );

  Widget _kp(String k, String v) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.all(10),
          decoration: _glass(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(k, style: const TextStyle(color: C.dim, fontSize: 11.5)), const SizedBox(height: 4), Text(v, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))]),
        ),
      );
}

/* ====================================================================== */
/*  VAULT ORBIT (Elite): 3D financial universe                             */
/* ====================================================================== */
class _OrbP {
  final String k, n, f;
  final double R, s, sp, tilt, a0;
  final List<Color> c;
  const _OrbP(this.k, this.n, this.R, this.s, this.sp, this.tilt, this.a0, this.c, this.f);
}

const List<_OrbP> kOrbP = [
  _OrbP('inc', 'Daromad', 165, 15, .30, .10, .6, [Color(0xFFF4FFF9), Color(0xFFB9E9D2), Color(0xFF3F6B59)], 'in'),
  _OrbP('exp', 'Xarajat', 230, 14, .22, -.16, 2.4, [Color(0xFFFFF6F3), Color(0xFFF0B3A7), Color(0xFF7A3B33)], 'out'),
  _OrbP('sav', "Jamg'arma", 295, 18, .16, .20, 4.1, [Color(0xFFFFFFFF), Color(0xFFD5DBE6), Color(0xFF5D6676)], 'in'),
  _OrbP('goal', 'Maqsadlar', 360, 15, .12, -.08, 5.5, [Color(0xFFFFFAF0), Color(0xFFE5D7AE), Color(0xFF6C5D33)], 'in'),
  _OrbP('ast', 'Aktivlar', 425, 21, .085, .13, 1.3, [Color(0xFFF6F9FF), Color(0xFFBFCBE2), Color(0xFF475069)], 'ring'),
];

class _OrbD {
  double bal = 0, inc = 0, exp = 0, sav = 0, goal = 0, ast = 0, tg = 0;
  int gn = 0, n = 0;
  bool same(_OrbD o) => bal == o.bal && inc == o.inc && exp == o.exp && sav == o.sav && goal == o.goal && tg == o.tg && gn == o.gn && n == o.n;
  double val(String k) => switch (k) { 'inc' => inc, 'exp' => exp, 'sav' => sav, 'goal' => goal, _ => ast };
}

_OrbD _orbData() {
  var bi = 0.0, bo = 0.0;
  for (final x in app.txs) {
    if (x.t == 'in') {
      bi += x.a;
    } else {
      bo += x.a;
    }
  }
  final mk = monthKeyOf(DateTime.now());
  final s = app.sums(mk);
  final gs = app.profile?.goals ?? <Goal>[];
  var sv = 0.0, tg = 0.0;
  for (final g in gs) {
    sv += g.saved;
    tg += g.target;
  }
  final d = _OrbD();
  d.bal = bi - bo;
  d.inc = s.i;
  d.exp = s.o;
  d.sav = sv;
  d.goal = tg > 0 ? math.min(1.0, sv / tg) * 100 : 0;
  d.ast = math.max(0.0, d.bal) + sv;
  d.tg = tg;
  d.gn = gs.length;
  d.n = app.listOf(mk).length;
  return d;
}

class _OrbPart {
  final int i;
  double t = 0;
  final double sp, j;
  _OrbPart(this.i, this.sp, this.j);
}

class _OrbStar {
  final double x, y, d, tw;
  _OrbStar(this.x, this.y, this.d, this.tw);
}

class _OrbHit {
  final int i;
  final double x, y, r;
  _OrbHit(this.i, this.x, this.y, this.r);
}

class _OrbState {
  double t = 0, intro = 0, ib = 0, yaw = .5, pitch = .5, uz = 1, zoom = 1, fx = 0, fy = 0, fz = 0, vel = 0, warp = 0, sc = 1, spawn = 0, chk = 0, w = 0, h = 0;
  int sel = -1;
  _OrbD? d;
  final Map<String, double> disp = {};
  final Map<int, double> pul = {};
  final List<_OrbPart> parts = [];
  final List<_OrbHit> scr = [];
  List<_OrbStar> stars = [];
}

class _OrbPainter extends CustomPainter {
  final _OrbState o;
  final int tick;
  _OrbPainter(this.o, this.tick);

  List<double> obRing(_OrbP p, double a) {
    final x = p.R * math.cos(a), z0 = p.R * math.sin(a);
    return [x, z0 * math.sin(p.tilt), z0 * math.cos(p.tilt)];
  }

  List<double> obP(double x, double y, double z) {
    x -= o.fx;
    y -= o.fy;
    z -= o.fz;
    final yw = o.yaw + (1 - o.ib) * 2.4, cy = math.cos(yw), sy = math.sin(yw), cp = math.cos(o.pitch), sp = math.sin(o.pitch);
    final x1 = x * cy - z * sy, z1 = x * sy + z * cy, y2 = y * cp + z1 * sp, z2 = z1 * cp - y * sp, k = 1100 / (1100 + z2) * o.sc;
    return [o.w / 2 + x1 * k, o.h / 2 - y2 * k, k, z2];
  }

  void halo(Canvas c, double x, double y, double r, Color col, double a) {
    if (r <= 0 || a <= 0) return;
    c.drawCircle(Offset(x, y), r, Paint()..shader = RadialGradient(colors: [col.withOpacity(a.clamp(0.0, 1.0)), col.withOpacity(0)]).createShader(Rect.fromCircle(center: Offset(x, y), radius: r)));
  }

  void sphere(Canvas c, double x, double y, double r, List<Color> col, double sx, double sy, double al) {
    if (r <= 0 || al <= 0) return;
    var lx = sx - x, ly = sy - y;
    final L = math.sqrt(lx * lx + ly * ly);
    if (L > 0) {
      lx /= L;
      ly /= L;
    }
    final ctr = Offset(x, y);
    c.saveLayer(Rect.fromCircle(center: ctr, radius: r * 1.4), Paint()..color = Colors.white.withOpacity(al.clamp(0.0, 1.0)));
    final fc = Offset(x + lx * r * .42, y + ly * r * .42);
    c.drawCircle(ctr, r, Paint()..shader = RadialGradient(center: Alignment((fc.dx - x) / r, (fc.dy - y) / r), radius: .525, colors: [Colors.white, col[0], col[1], col[2]], stops: const [0, .16, .55, 1]).createShader(Rect.fromCircle(center: ctr, radius: r)));
    c.save();
    c.clipPath(Path()..addOval(Rect.fromCircle(center: ctr, radius: r)));
    for (var j = -1; j <= 1; j++) {
      c.save();
      c.translate(x, y + j * r * .44);
      c.rotate(-.32);
      c.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 2.6, height: r * .4), Paint()..color = Colors.white.withOpacity(.11)..style = PaintingStyle.stroke..strokeWidth = r * .13);
      c.restore();
    }
    final sc2 = Offset(x + lx * r * .35, y + ly * r * .35);
    c.drawRect(Rect.fromCircle(center: ctr, radius: r), Paint()..shader = RadialGradient(colors: [const Color(0x00000000), const Color(0x00000000), Colors.black.withOpacity(.82)], stops: const [0, .55, 1]).createShader(Rect.fromCircle(center: sc2, radius: r * 1.4)));
    c.restore();
    c.drawCircle(ctr, r, Paint()..color = Colors.white.withOpacity(.22)..style = PaintingStyle.stroke);
    c.restore();
  }

  void reticle(Canvas c, double x, double y, double r, Color col) {
    c.save();
    c.translate(x, y);
    c.rotate(o.t * .9);
    final p = Paint()..color = col.withOpacity(.85)..style = PaintingStyle.stroke..strokeWidth = 1.4;
    for (var i = 0; i < 4; i++) {
      c.drawArc(Rect.fromCircle(center: Offset.zero, radius: r), i * 1.5708 + .15, .95, false, p);
    }
    c.restore();
  }

  void label(Canvas c, String s, double x, double y, double a, double fs) {
    final tp = TextPainter(text: TextSpan(text: s, style: TextStyle(color: const Color(0xFFDEE4F0).withOpacity(a.clamp(0.0, 1.0)), fontSize: fs, fontWeight: FontWeight.w600)), textDirection: TextDirection.ltr)..layout();
    tp.paint(c, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  @override
  void paint(Canvas c, Size size) {
    final w = o.w = size.width, h = o.h = size.height, T = o.t, ib = o.ib;
    final d = o.d ?? _orbData();
    c.drawRect(Offset.zero & size, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF05070D), Color(0xFF0A0E18)]).createShader(Offset.zero & size));
    halo(c, w * .3 + math.cos(T * .05) * 40 - o.yaw * 18, h * .32, w * .7, const Color(0xFF788CBE), .1);
    halo(c, w * .78 + math.sin(T * .04) * 30, h * .72, w * .6, const Color(0xFFA0A0B9), .07);
    for (final s in o.stars) {
      final px = (((s.x - o.yaw * s.d * 90) % w) + w) % w, py = s.y + o.pitch * s.d * 50, tw = .55 + .45 * math.sin(T * 1.6 + s.tw);
      if (o.warp > .06) {
        final dx = px - w / 2, dy = py - h / 2, L = math.sqrt(dx * dx + dy * dy);
        final ln = o.warp * s.d * 34;
        c.drawLine(Offset(px, py), Offset(px + dx / (L == 0 ? 1 : L) * ln, py + dy / (L == 0 ? 1 : L) * ln), Paint()..color = const Color(0xFFD7E1F5).withOpacity(.35 * s.d)..strokeWidth = .8);
      }
      c.drawRect(Rect.fromLTWH(px, py, s.d * 1.7, s.d * 1.7), Paint()..color = const Color(0xFFE1E8F8).withOpacity((.75 * s.d * tw).clamp(0.0, 1.0)));
    }
    final sun = obP(0, 0, 0);
    final items = <({double z, int i, List<double> pp, double vis})>[];
    o.scr.clear();
    for (var i = 0; i < kOrbP.length; i++) {
      final p = kOrbP[i];
      final vis = (ib * 5 - i * .55).clamp(0.0, 1.0), sel = o.sel == i;
      final pts = [for (var j = 0; j <= 96; j++) obP(obRing(p, j / 96 * 6.2832)[0], obRing(p, j / 96 * 6.2832)[1], obRing(p, j / 96 * 6.2832)[2])];
      for (var j = 0; j < 96; j++) {
        final a = pts[j], b = pts[j + 1];
        final dep = math.max(.25, math.min(1.0, 1 - a[3] / (p.R * 2)));
        final al = ((sel ? .55 : .17) * vis * dep + (o.pul[i] ?? 0) * .25 * dep).clamp(0.0, 1.0);
        c.drawLine(Offset(a[0], a[1]), Offset(b[0], b[1]), Paint()..color = const Color(0xFFCDD6E8).withOpacity(al)..strokeWidth = sel ? 1.6 : 1);
      }
      final q = obRing(p, p.a0 + T * p.sp);
      items.add((z: obP(q[0], q[1], q[2])[3], i: i, pp: obP(q[0], q[1], q[2]), vis: vis));
    }
    // particles
    for (final q in o.parts) {
      final p = kOrbP[q.i], pos = obRing(p, p.a0 + T * p.sp), u = q.t, e = p.f == 'out' ? u : 1 - u;
      double x = pos[0] * (1 - e), y = pos[1] * (1 - e) + math.sin(u * math.pi) * 28 * q.j, z = pos[2] * (1 - e);
      if (p.f == 'out') {
        x = pos[0] * u;
        y = pos[1] * u + math.sin(u * math.pi) * 28 * q.j;
        z = pos[2] * u;
      }
      final s = obP(x, y, z), al = math.sin(u * math.pi) * .9, rr = math.max(1.0, 2.2 * s[2]);
      halo(c, s[0], s[1], rr * 4, p.k == 'exp' ? const Color(0xFFFFA08C) : p.k == 'goal' ? const Color(0xFFF5E1A0) : const Color(0xFFBEF0DC), al * .55);
      c.drawCircle(Offset(s[0], s[1]), rr, Paint()..color = Colors.white.withOpacity(al.clamp(0.0, 1.0)));
    }
    items.add((z: sun[3], i: 5, pp: sun, vis: (ib * 3).clamp(0.0, 1.0)));
    items.sort((a, b) => b.z.compareTo(a.z));
    for (final it in items) {
      final pp = it.pp, al = it.vis;
      if (al <= 0) continue;
      if (it.i == 5) {
        final pl = o.pul[5] ?? 0;
        final r = 34 * pp[2] * (.6 + .4 * al) * (1 + pl * .18), neg = d.bal < 0, ps = .85 + .15 * math.sin(T * 1.7) + pl * .6;
        halo(c, pp[0], pp[1], r * 5.2, neg ? const Color(0xFFFF7864) : const Color(0xFFBED2FF), .3 * ps * al);
        halo(c, pp[0], pp[1], r * 2.2, neg ? const Color(0xFFFFAA96) : const Color(0xFFEBF2FF), .5 * ps * al);
        sphere(c, pp[0], pp[1], r, d.bal >= 0 ? const [Color(0xFFFFFFFF), Color(0xFFD9DFEA), Color(0xFF69738A)] : const [Color(0xFFFFF3F0), Color(0xFFF0A89C), Color(0xFF7A3B33)], pp[0] - r, pp[1] - r, al);
        for (var k = 0; k < 3; k++) {
          final rr = r * (1.55 + k * .42), ph = T * (.5 - k * .17);
          c.save();
          c.translate(pp[0], pp[1]);
          c.rotate(ph * .3 - .4);
          c.drawOval(Rect.fromCenter(center: Offset.zero, width: rr * 2, height: rr * 2 * math.max(.18, math.sin(o.pitch))), Paint()..color = const Color(0xFFD7E0F0).withOpacity(((.38 - k * .1) * al).clamp(0.0, 1.0))..style = PaintingStyle.stroke..strokeWidth = 1);
          c.restore();
        }
        o.scr.add(_OrbHit(5, pp[0], pp[1], r * 1.7));
        if (o.sel == 5) reticle(c, pp[0], pp[1], r * 2.3, const Color(0xFFE8ECF3));
        continue;
      }
      final p = kOrbP[it.i], pl = o.pul[it.i] ?? 0;
      final r = p.s * pp[2] * (.5 + .5 * al) * (1 + pl * .3);
      halo(c, pp[0], pp[1], r * 3.4, p.c[1], (.16 + pl * .5) * al);
      if (pl > .02) c.drawCircle(Offset(pp[0], pp[1]), r * (1.2 + (1 - pl) * 3.5), Paint()..color = p.c[1].withOpacity((pl * .6).clamp(0.0, 1.0))..style = PaintingStyle.stroke..strokeWidth = 1.5);
      final ring = p.f == 'ring', tl = o.pitch * .6 + .1;
      void rg(double mul, double a0, double sw, double sweepStart, Color col) {
        final rr = r * mul;
        c.save();
        c.translate(pp[0], pp[1]);
        c.rotate(-.3);
        c.drawArc(Rect.fromCenter(center: Offset.zero, width: rr * 2, height: rr * 2 * math.sin(tl)), sweepStart, math.pi, false, Paint()..color = col..style = PaintingStyle.stroke..strokeWidth = math.max(1.0, r * sw));
        c.restore();
      }
      if (ring) rg(2.1, 0, .09, math.pi, const Color(0xFFD2DCF0).withOpacity(.5 * al));
      sphere(c, pp[0], pp[1], r, p.c, sun[0], sun[1], al);
      if (ring) {
        rg(2.1, 0, .12, 0, const Color(0xFFEBF0FC).withOpacity(.8 * al));
        rg(2.55, 0, .05, 0, const Color(0xFFBEC8DC).withOpacity(.35 * al));
      }
      label(c, p.n, pp[0], pp[1] + r * (ring ? 3.2 : 1.9) + 10, .78 * al * (o.sel == it.i || o.sel < 0 ? 1 : .45), math.max(9.0, math.min(13.0, 11 * pp[2] * o.zoom * .9 + 2)));
      o.scr.add(_OrbHit(it.i, pp[0], pp[1], r * (ring ? 2.4 : 1.2)));
      if (o.sel == it.i) reticle(c, pp[0], pp[1], r * (ring ? 3.1 : 2.1), const Color(0xFFF1F4FA));
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter o) => true;
}

class OrbitTab extends StatefulWidget {
  final ShellApi api;
  const OrbitTab({super.key, required this.api});
  @override
  State<OrbitTab> createState() => _OrbitTabState();
}

class _OrbitTabState extends State<OrbitTab> with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(vsync: this, duration: const Duration(seconds: 3600))..repeat();
  final o = _OrbState();
  final rnd = math.Random();
  double _last = 0, _zs = 1;
  int tick = 0;
  bool hint = true;
  Size _sz = Size.zero;

  @override
  void initState() {
    super.initState();
    _ac.addListener(_tick);
    Future<void>.delayed(const Duration(seconds: 6), () {
      if (mounted) setState(() => hint = false);
    });
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  void _stars(Size s) {
    if (_sz == s) return;
    _sz = s;
    o.w = s.width;
    o.h = s.height;
    o.stars = [for (var i = 0; i < 230; i++) _OrbStar(rnd.nextDouble() * s.width, rnd.nextDouble() * s.height, .15 + rnd.nextDouble() * .85, rnd.nextDouble() * 6)];
  }

  List<double> _ring(_OrbP p, double a) {
    final x = p.R * math.cos(a), z0 = p.R * math.sin(a);
    return [x, z0 * math.sin(p.tilt), z0 * math.cos(p.tilt)];
  }

  void _tick() {
    final now = _ac.value * 3600.0;
    var dt = now - _last;
    if (dt < 0) dt += 3600;
    _last = now;
    dt = math.min(.05, dt);
    o.t += dt;
    final T = o.t;
    o.intro = math.min(1.0, o.intro + dt / 3.6);
    o.ib = 1 - math.pow(1 - o.intro, 3).toDouble();
    final a = 1 - math.exp(-dt * 3.2);
    double tx = 0, ty = 0, tz = 0;
    if (o.sel >= 0 && o.sel < 5) {
      final q = _ring(kOrbP[o.sel], kOrbP[o.sel].a0 + T * kOrbP[o.sel].sp);
      tx = q[0];
      ty = q[1];
      tz = q[2];
    }
    o.fx += (tx - o.fx) * a;
    o.fy += (ty - o.fy) * a;
    o.fz += (tz - o.fz) * a;
    final tg = o.uz * (o.sel >= 0 ? (o.sel == 5 ? 1.5 : 2.4) : 1), z0 = o.zoom;
    o.zoom += (tg - o.zoom) * a;
    o.warp = math.min(2.0, (o.zoom - z0).abs() / math.max(dt, .001) * .5 + (1 - o.intro) * 1.4);
    if (!_drag) {
      o.yaw += o.vel * dt;
      o.vel *= math.exp(-dt * 2.2);
      if (o.sel < 0) o.yaw += dt * .07;
    }
    o.pitch = o.pitch.clamp(.12, 1.25);
    o.sc = math.min(o.w, o.h * 1.05) / 880 * o.zoom * (.35 + .65 * o.ib);
    o.chk -= dt;
    if (o.chk <= 0) {
      o.chk = .8;
      final d = _orbData(), old = o.d;
      if (old != null) {
        for (var i = 0; i < kOrbP.length; i++) {
          if ((d.val(kOrbP[i].k) - old.val(kOrbP[i].k)).abs() > .001) o.pul[i] = 1;
        }
        if ((d.bal - old.bal).abs() > .001) o.pul[5] = 1;
      }
      o.d = d;
    }
    final b = 1 - math.exp(-dt * 4.5), d2 = o.d;
    if (d2 != null) {
      for (final k in ['bal', 'inc', 'exp', 'sav', 'goal', 'ast']) {
        final tv = switch (k) { 'bal' => d2.bal, 'inc' => d2.inc, 'exp' => d2.exp, 'sav' => d2.sav, 'goal' => d2.goal, _ => d2.ast };
        o.disp[k] = (o.disp[k] ?? 0) + (tv - (o.disp[k] ?? 0)) * b;
      }
    }
    for (final k in o.pul.keys.toList()) {
      o.pul[k] = math.max(0.0, o.pul[k]! - dt * .8);
    }
    if (d2 != null && o.intro > .55) {
      final mx = math.max(math.max(d2.inc, d2.exp), math.max(d2.sav, 1.0));
      o.spawn -= dt;
      if (o.spawn <= 0) {
        o.spawn = .09;
        for (var i = 0; i < 4; i++) {
          final v = d2.val(kOrbP[i].k);
          if (v > 0 && rnd.nextDouble() < .25 + .6 * math.min(1.0, (kOrbP[i].k == 'goal' ? d2.goal / 100 * mx : v) / mx)) {
            o.parts.add(_OrbPart(i, .22 + rnd.nextDouble() * .3, rnd.nextDouble() * 2 - 1));
          }
        }
        if (o.parts.length > 140) o.parts.removeRange(0, 20);
      }
    }
    for (final p in o.parts) {
      p.t += p.sp * dt;
    }
    o.parts.removeWhere((p) => p.t >= 1);
    tick++;
    if (mounted) setState(() {});
  }

  bool _drag = false;
  double _moved = 0;

  void _pick(Offset pos) {
    var best = -2;
    var bd = 1e9;
    for (final s in o.scr) {
      final dd = math.sqrt(math.pow(pos.dx - s.x, 2) + math.pow(pos.dy - s.y, 2));
      if (dd < s.r + 12 && dd / math.max(s.r, 1) < bd) {
        bd = dd / math.max(s.r, 1);
        best = s.i;
      }
    }
    if (best >= 0) _sel(best);
  }

  void _sel(int i) {
    o.sel = i == o.sel ? -1 : i;
    hint = false;
  }

  String _v(String k, double v) => k == 'goal' ? '${v.round()}%' : mny(v);

  @override
  Widget build(BuildContext context) {
    final d = o.d ?? _orbData();
    final i = o.sel;
    String nm = 'Koinot', sub = "Sudrab aylantiring, chimchilab yaqinlashtiring. Sayyorani bosing — kamera unga uchib boradi.", k = '';
    Color col = C.dim;
    double bar = 0;
    if (i >= 0) {
      if (i == 5) {
        nm = 'Umumiy balans';
        k = 'bal';
        col = const Color(0xFFE8ECF3);
        sub = d.bal >= 0 ? 'Barcha daromad − barcha xarajat. Koinot markazi barqaror yonmoqda.' : 'Xarajat daromaddan oshgan — markaziy yulduz qizarmoqda.';
        bar = d.bal > 0 ? 100 : 0;
      } else {
        final p = kOrbP[i];
        nm = p.n;
        k = p.k;
        col = p.c[1];
        final mx = math.max(math.max(d.inc, d.exp), 1.0);
        switch (k) {
          case 'inc':
            sub = 'Shu oy ${d.n} ta operatsiya ichida tushgan daromad.';
            bar = d.inc / mx * 100;
          case 'exp':
            sub = d.inc > 0 ? 'Shu oy daromadning ${(d.exp / d.inc * 100).round()}% i sarflangan.' : 'Shu oydagi jami xarajat.';
            bar = d.exp / mx * 100;
          case 'sav':
            sub = d.gn > 0 ? "${d.gn} ta maqsad bo'yicha yig'ilgan jamg'arma." : "Hali maqsad yo'q — Maqsadlar bo'limidan qo'shing.";
            bar = d.ast > 0 ? d.sav / d.ast * 100 : 0;
          case 'goal':
            sub = d.tg > 0 ? "${mny(d.sav)} / ${mny(d.tg)} yig'ildi." : "Maqsad qo'yilmagan.";
            bar = d.goal;
          default:
            sub = "Musbat balans + jamg'arma = umumiy aktivlar.";
            bar = d.ast > 0 ? 100 : 0;
        }
      }
    }
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
      const Text('VAULT ORBIT', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const Text('Your Financial Universe', style: TextStyle(color: C.dim, fontSize: 13.5)),
      const SizedBox(height: 12),
      ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 420,
          child: LayoutBuilder(builder: (ctx, bc) {
            _stars(Size(bc.maxWidth, 420));
            return Stack(fit: StackFit.expand, children: [
              GestureDetector(
                onScaleStart: (d) {
                  _drag = true;
                  _moved = 0;
                  _zs = o.uz;
                  o.vel = 0;
                },
                onScaleUpdate: (d) {
                  _moved += d.focalPointDelta.distance;
                  if (d.pointerCount >= 2) {
                    o.uz = (_zs * d.scale).clamp(.6, 2.6);
                    _moved += 10;
                  } else {
                    o.yaw += d.focalPointDelta.dx * .006;
                    o.pitch += d.focalPointDelta.dy * .005;
                    o.vel = (d.focalPointDelta.dx * .006 * 60).clamp(-3.0, 3.0);
                  }
                },
                onScaleEnd: (_) => _drag = false,
                onTapUp: (d) => _pick(d.localPosition),
                child: CustomPaint(painter: _OrbPainter(o, tick)),
              ),
              Positioned(
                left: 14,
                top: 12,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('UMUMIY BALANS', style: TextStyle(color: C.dim, fontSize: 10.5, letterSpacing: 1.6, fontWeight: FontWeight.w700)),
                  Text(mny(o.disp['bal'] ?? 0), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                ]),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Row(children: [
                  _ob('Boshiga', () => setState(() {
                        o.sel = -1;
                        o.uz = 1;
                        o.yaw = .5;
                        o.pitch = .5;
                        o.vel = 0;
                      })),
                  const SizedBox(width: 6),
                  _ob('Kino', () => setState(() {
                        o.sel = -1;
                        o.uz = 1;
                        o.intro = 0;
                        o.disp.clear();
                      })),
                ]),
              ),
              if (hint) const Positioned(left: 0, right: 0, bottom: 12, child: Center(child: Text('SUDRAB AYLANTIRING · YAQINLASHTIRING · TANLANG', style: TextStyle(color: C.mute, fontSize: 10, letterSpacing: 1.2)))),
            ]);
          }),
        ),
      ),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final e in [(5, 'Balans', const Color(0xFFE8ECF3)), for (var x = 0; x < 5; x++) (x, kOrbP[x].n, kOrbP[x].c[1])])
          ChoiceChip(
            avatar: CircleAvatar(radius: 5, backgroundColor: e.$3),
            label: Text(e.$2),
            selected: o.sel == e.$1,
            onSelected: (_) => setState(() => _sel(e.$1)),
          ),
      ]),
      const SizedBox(height: 12),
      uCard(nm, children: [
        if (i >= 0)
          Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [CircleAvatar(radius: 5, backgroundColor: col), const SizedBox(width: 8), Text(_v(k, o.disp[k] ?? 0), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))])),
        uSmall(sub),
        if (i >= 0) uBar(math.max(2.0, math.min(100.0, bar)) / 100, col),
      ]),
      const Center(child: Padding(padding: EdgeInsets.only(top: 6), child: Text('VAULT ORBIT — Elite Exclusive · FROM EIGHTEEN.', style: TextStyle(color: C.mute, fontSize: 11, letterSpacing: 1.2)))),
    ]);
  }

  Widget _ob(String l, VoidCallback f) => GestureDetector(onTap: f, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10), border: Border.all(color: C.line)), child: Text(l, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))));
}

/* ====================================================================== */
/*  VAULT TIME MACHINE (Ultra, read-only)                                  */
/* ====================================================================== */
({double i, double o, double bal, int n}) tmCalc(String d) {
  var i = 0.0, o = 0.0, n = 0;
  for (final x in app.txs) {
    if (x.d.isEmpty || x.a < 0 || x.d.compareTo(d) > 0) continue;
    n++;
    if (x.t == 'in') {
      i += x.a;
    } else {
      o += x.a;
    }
  }
  return (i: r2(i), o: r2(o), bal: r2(i - o), n: n);
}

String tmFirst() {
  var m = '';
  for (final x in app.txs) {
    if (x.d.isNotEmpty && (m.isEmpty || x.d.compareTo(m) < 0)) m = x.d;
  }
  return m;
}

String tmBack(String t, int k, String u) {
  final d = parseDay(t);
  if (u == 'd') return dayKey(d.subtract(Duration(days: k)));
  var y = d.year, m = d.month - 1 - k;
  while (m < 0) {
    m += 12;
    y--;
  }
  final l = DateTime(y, m + 2, 0).day;
  return '$y-${two(m + 1)}-${two(math.min(d.day, l))}';
}

String tmDL(String d) => '${int.parse(d.substring(8, 10))} ${monthName(int.parse(d.substring(5, 7))).toLowerCase()} ${d.substring(0, 4)}';

class _PortalPainter extends CustomPainter {
  final double t, dive, kick, px, py;
  final List<Offset> stars;
  _PortalPainter(this.t, this.dive, this.kick, this.px, this.py, this.stars);
  @override
  void paint(Canvas c, Size size) {
    final ctr = size.center(Offset.zero).translate(px * 10, py * 8);
    final base = math.min(size.width, size.height) * .22;
    final e = dive * dive * (3 - 2 * dive);
    // background glow
    c.drawRect(Offset.zero & size, Paint()..shader = RadialGradient(colors: [const Color(0xFF1A2230).withOpacity(.9), const Color(0xFF05070B)]).createShader(Offset.zero & size));
    // stars flying toward the viewer
    final sp = (.2 + kick * 2 + e * 5);
    for (var i = 0; i < stars.length; i++) {
      final s = stars[i];
      final z = ((s.dx * 7 + t * (.35 + sp * .25) * (1 + (i % 5) * .15)) % 1.0);
      final r = z * size.width * .8;
      final a = s.dy * math.pi * 2;
      final p = ctr + Offset(math.cos(a), math.sin(a)) * (r * (.2 + s.dx * .9));
      c.drawCircle(p, .6 + z * 1.6, Paint()..color = const Color(0xFFDDE3EE).withOpacity(math.min(1, z * .9)));
    }
    // tunnel rings
    for (var i = 0; i < 7; i++) {
      final z = ((i / 7) + t * (.08 + e * .9)) % 1.0;
      final r = base * (.5 + z * 3.2 * (1 + e * 1.5));
      c.drawCircle(ctr, r, Paint()..color = const Color(0xFFC9CED8).withOpacity((1 - z) * .55)..style = PaintingStyle.stroke..strokeWidth = 1 + z * 2);
    }
    // metallic tori (faux 3D: rotating ellipses)
    final specs = [(1.7, 5.0), (2.1, 3.6), (2.5, 4.6), (2.9, 2.6)];
    for (var i = 0; i < specs.length; i++) {
      final r = base * specs[i].$1 * (1 + e * 1.6) * .62;
      final rot = t * (i.isEven ? 1 : -1) * (.4 + i * .12 + e * 3);
      final tiltX = .35 + math.sin(t * .9 + i) * .12 + py * .25;
      c.save();
      c.translate(ctr.dx, ctr.dy);
      c.rotate(rot);
      c.scale(1, math.cos(tiltX).abs().clamp(.45, 1.0));
      c.drawCircle(Offset.zero, r, Paint()
        ..shader = SweepGradient(colors: const [Color(0xFFF4F6FA), Color(0xFF7D8696), Color(0xFFD5DAE3), Color(0xFF4E5666), Color(0xFFF4F6FA)], transform: GradientRotation(t + i)).createShader(Rect.fromCircle(center: Offset.zero, radius: r))
        ..style = PaintingStyle.stroke
        ..strokeWidth = specs[i].$2);
      c.restore();
    }
    // glass core
    final core = base * .95 * (1 + e * 2.2);
    c.drawCircle(ctr, core, Paint()..shader = RadialGradient(colors: [const Color(0xFF0B0E13).withOpacity(.85), const Color(0xFF0B0E13).withOpacity(.2)]).createShader(Rect.fromCircle(center: ctr, radius: core)));
    c.drawCircle(ctr, core, Paint()..color = Colors.white.withOpacity(.12 + e * .4)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    if (e > .6) c.drawRect(Offset.zero & size, Paint()..color = Colors.white.withOpacity((e - .6) * .9));
  }

  @override
  bool shouldRepaint(covariant _PortalPainter o) => true;
}

class TimeTab extends StatefulWidget {
  final ShellApi api;
  const TimeTab({super.key, required this.api});
  @override
  State<TimeTab> createState() => _TimeTabState();
}

class _TimeTabState extends State<TimeTab> with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(vsync: this, duration: const Duration(seconds: 60))..repeat();
  late final List<Offset> _stars = List.generate(90, (i) => Offset(math.Random(i * 7 + 1).nextDouble(), math.Random(i * 13 + 5).nextDouble()));
  String d = todayStr();
  String mode = 'intro'; // intro | travel | result
  double dive = 0, kick = 0, px = 0, py = 0;
  int _t0 = 0;
  List<Tx> evs = [];
  Tx? evSel;
  double _last = 0;

  static const _pre = [('Bugun', 0, 'd'), ('7 kun oldin', 7, 'd'), ('30 kun oldin', 30, 'd'), ('3 oy oldin', 3, 'm'), ('6 oy oldin', 6, 'm'), ('12 oy oldin', 12, 'm')];

  @override
  void initState() {
    super.initState();
    _ac.addListener(_tick);
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  void _tick() {
    final now = _ac.value * 60.0;
    var dt = now - _last;
    if (dt < 0) dt += 60;
    _last = now;
    dt = math.min(.05, dt);
    var ch = false;
    if (mode == 'travel') {
      final p = math.min(1.0, (DateTime.now().millisecondsSinceEpoch - _t0) / 2300);
      dive = p;
      ch = true;
      if (p >= 1) {
        _arrive();
        return;
      }
    } else if (dive > .001) {
      dive += (0 - dive) * math.min(1.0, dt * 2.5);
      ch = true;
    }
    if (kick > .001) {
      kick *= math.max(0, 1 - dt * 2.2);
      ch = true;
    }
    if (ch && mounted) setState(() {});
  }

  void _go() {
    final f = tmFirst();
    if (f.isEmpty || d.compareTo(f) < 0 || d.compareTo(todayStr()) > 0) return;
    setState(() {
      mode = 'travel';
      _t0 = DateTime.now().millisecondsSinceEpoch;
      dive = 0;
    });
  }

  void _arrive() {
    if (mode != 'travel') return;
    setState(() {
      mode = 'result';
      dive = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = app.profile!;
    if (!p.isUltra) {
      return ListView(padding: const EdgeInsets.all(16), children: [
        const Text('VAULT TIME MACHINE', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const Text('Ultra Exclusive', style: TextStyle(color: C.dim)),
        const SizedBox(height: 16),
        uCard('Faqat ULTRA tarifida', children: [uSmall("Vaqt mashinasi hisobingizdagi haqiqiy tarixni o'qib, o'tmishdagi holatingizni bugun bilan taqqoslaydi."), PrimaryButton(label: "ULTRA tarifini ko'rish", onTap: () => widget.api.show('plans'))]),
      ]);
    }
    final f = tmFirst();
    final t = todayStr();
    final ok = f.isNotEmpty && d.compareTo(f) >= 0 && d.compareTo(t) <= 0;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
      const Text('VAULT TIME MACHINE', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
      const Text('Ultra Exclusive', style: TextStyle(color: C.dim, fontSize: 13.5)),
      const SizedBox(height: 12),
      _stage(),
      const SizedBox(height: 14),
      if (mode == 'intro') _picker(f, t, ok),
      if (mode == 'result') _result(f, t),
    ]);
  }

  Widget _stage() => ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: GestureDetector(
          onPanUpdate: (u) => setState(() {
            px = (px + u.delta.dx / 120).clamp(-1.0, 1.0);
            py = (py + u.delta.dy / 120).clamp(-1.0, 1.0);
          }),
          child: SizedBox(
            height: 300,
            child: Stack(fit: StackFit.expand, children: [
              AnimatedBuilder(animation: _ac, builder: (_, __) => CustomPaint(painter: _PortalPainter(_ac.value * 60, dive, kick, px, py, _stars))),
              Positioned(
                left: 16,
                right: 16,
                top: 16,
                child: Opacity(
                  opacity: mode == 'travel' ? math.max(0, 1 - dive * 3) : 1,
                  child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('FROM EIGHTEEN · ULTRA EXCLUSIVE', style: TextStyle(color: Color(0xFFA9B1C0), fontSize: 10.5, letterSpacing: 1.6, fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text('VAULT TIME MACHINE', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                    Text('YOUR MONEY. YOUR HISTORY.', style: TextStyle(color: Color(0xFFDDE3EE), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
                  ]),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: mode == 'travel'
                    ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(tmDL(d), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                        TextButton(onPressed: _arrive, child: const Text("O'tkazib yuborish ›", style: TextStyle(color: Color(0xFFDDE3EE)))),
                      ])
                    : Text(mode == 'result' ? tmDL(d) : "Moliyaviy tarixingga qayt. O'tmishdagi holatingni bugungi kun bilan taqqosla.", style: TextStyle(color: const Color(0xFFDDE3EE), fontSize: mode == 'result' ? 22 : 13, fontWeight: mode == 'result' ? FontWeight.w800 : FontWeight.w500)),
              ),
            ]),
          ),
        ),
      );

  Widget _picker(String f, String t, bool ok) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Qaysi sanaga qaytamiz?', style: TextStyle(color: C.dim, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final p in _pre)
          Builder(builder: (_) {
            final dd = p.$2 > 0 ? tmBack(t, p.$2, p.$3) : t;
            final off = f.isEmpty || dd.compareTo(f) < 0;
            return ChoiceChip(
              label: Column(mainAxisSize: MainAxisSize.min, children: [Text(p.$1), if (off) const Text("ma'lumot yo'q", style: TextStyle(fontSize: 9.5))]),
              selected: dd == d,
              onSelected: off ? null : (_) => setState(() => d = dd),
              selectedColor: Colors.white.withOpacity(.18),
              backgroundColor: const Color(0x0AFFFFFF),
              side: BorderSide(color: dd == d ? Colors.white70 : C.line),
            );
          }),
      ]),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: () async {
          final x = await showDatePicker(context: context, initialDate: parseDay(d), firstDate: f.isEmpty ? parseDay(t) : parseDay(f), lastDate: parseDay(t));
          if (x != null) setState(() => d = dayKey(x));
        },
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), side: const BorderSide(color: C.line), foregroundColor: C.ink),
        child: Text('Aniq sana (kalendar): $d'),
      ),
      const SizedBox(height: 8),
      Text.rich(TextSpan(style: const TextStyle(color: C.dim, fontSize: 12.5), children: [const TextSpan(text: 'Tanlangan sana: '), TextSpan(text: tmDL(d), style: const TextStyle(fontWeight: FontWeight.w800, color: C.ink)), TextSpan(text: ok ? '' : " — bu sanada ma'lumot yo'q")])),
      const SizedBox(height: 4),
      Text(f.isEmpty ? "Hisobda hali tranzaksiya yo'q. Tarix faqat siz yozgan yozuvlardan olinadi va uydirilmaydi." : 'Birinchi yozuv: ${tmDL(f)}. Undan oldingi sanalar yopiq.', style: const TextStyle(color: C.dim, fontSize: 12.5)),
      const SizedBox(height: 12),
      FilledButton(
        onPressed: ok ? _go : null,
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), backgroundColor: const Color(0xFFE6EAF2), foregroundColor: const Color(0xFF0B0E13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        child: const Text('START TIME TRAVEL', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.4)),
      ),
    ]);
  }

  Widget _tcard(String title, List<Widget> kids) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: _glass(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(title, style: const TextStyle(color: C.dim, fontSize: 11.5, letterSpacing: 1.2, fontWeight: FontWeight.w700)), const SizedBox(height: 8), ...kids]),
      );

  Widget _kv(String k, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [Expanded(child: Text(k, style: const TextStyle(color: C.dim, fontSize: 13))), Text(v, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5))]));

  Widget _result(String f, String t) {
    if (f.isEmpty || d.compareTo(f) < 0 || d.compareTo(t) > 0) {
      return Column(children: [
        _tcard("Bu sanada ma'lumot yo'q", [Text("Hisobdagi birinchi yozuv: ${f.isEmpty ? "hali yo'q" : tmDL(f)}. Mavjud bo'lmagan tarix yaratilmaydi.", style: const TextStyle(color: C.dim))]),
        _back(),
      ]);
    }
    final p = app.profile!;
    final A = tmCalc(d), B = tmCalc(t);
    final dB = B.bal - A.bal, dI = B.i - A.i, dO = B.o - A.o;
    var gt = 0.0, gv = 0.0;
    for (final g in p.goals) {
      gt += g.target;
      gv += g.saved;
    }
    final nw = p.mp('nw');
    final nwA = nw[d.substring(0, 7)], nwB = nw[t.substring(0, 7)];
    evs = app.txs.where((x) => x.d.isNotEmpty && x.d.compareTo(d) >= 0 && x.d.compareTo(t) <= 0).toList()..sort((a, b) => b.a.compareTo(a.a));
    evs = evs.take(10).toList()..sort((a, b) => a.d.compareTo(b.d));
    final day = app.txs.where((x) => x.d == d).toList();
    final maxD = parseDay(t).difference(parseDay(f)).inDays;
    final cur = parseDay(d).difference(parseDay(f)).inDays;
    Widget col(String h, dynamic X) => Expanded(child: _tcard(h, [_kv('Balans', mny(X.bal as num)), _kv('Jami daromad', mny(X.i as num)), _kv('Jami xarajat', mny(X.o as num)), _kv('Yozuvlar', '${X.n}')]));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _tcard('VAQT SLAYDERI · ${tmDL(d)}', [
        Slider(
          value: cur.toDouble().clamp(0, math.max(1, maxD).toDouble()),
          min: 0,
          max: math.max(1, maxD).toDouble(),
          divisions: math.max(1, maxD),
          activeColor: Colors.white70,
          onChanged: (v) => setState(() {
            d = dayKey(parseDay(f).add(Duration(days: v.round())));
            kick = 1;
          }),
        ),
        const Text("Slayderni suring: sana o'zgaradi, hisob avtomatik qayta hisoblanadi.", style: TextStyle(color: C.dim, fontSize: 12)),
      ]),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [col("O'TMISH · ${tmDL(d)}", A), const SizedBox(width: 10), col('BUGUN · ${tmDL(t)}', B)]),
      _tcard("O'ZGARISH", [_kv("Balans o'zgarishi", sdn(dB)), _kv("Daromad o'zgarishi", sdn(dI)), _kv("Xarajat o'zgarishi", sdn(dO)), const SizedBox(height: 6), Text("Shu sanadan beri balansingiz ${mny(dB.abs())}${dB > 0 ? ' ga oshdi' : dB < 0 ? ' ga kamaydi' : " — o'zgarmadi"}. Shu davrda ${mny(dI)} daromad va ${mny(dO)} xarajat yozilgan.", style: const TextStyle(color: C.dim, fontSize: 12.5, height: 1.4))]),
      _tcard("MAQSADLAR VA JAMG'ARMA", [
        Text("${p.goals.isNotEmpty ? 'Hozir ${p.goals.length} ta maqsad: ${mny(gv)} / ${mny(gt)}. ' : "Hozircha maqsad yo'q. "}Maqsadlarning o'tmishdagi holati saqlanmaydi, shuning uchun taqqoslanmaydi.", style: const TextStyle(color: C.dim, fontSize: 12.5)),
        if (nwA != null) _kv('Sof boylik (shu oy yozuvi)', mny(nwA as num)),
        if (nwB != null && nwA != null) _kv('Sof boylik (bu oy)', mny(nwB as num)),
      ]),
      _tcard('SHU KUNGI YOZUVLAR', [if (day.isEmpty) const Text("Bu kuni yozuv yo'q.", style: TextStyle(color: C.dim)), for (final x in day) TxTile(x)]),
      _tcard('TIMELINE · ENG YIRIK VOQEALAR', [
        if (evs.isEmpty) const Text("Bu davrda yozuv yo'q.", style: TextStyle(color: C.dim)),
        for (final x in evs)
          InkWell(
            onTap: () => setState(() {
              evSel = x;
              kick = x.t == 'in' ? 1 : 1.6;
            }),
            child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [Expanded(child: Text('${tmDL(x.d)} · ${catOf(x.t, x.c).name}', style: const TextStyle(fontSize: 13))), Text('${x.t == 'in' ? '+' : '−'}${mny(x.a)}', style: TextStyle(fontWeight: FontWeight.w800, color: x.t == 'in' ? C.accent : C.out))])),
          ),
        if (evSel != null) ...[const Divider(color: C.line), Text(tmDL(evSel!.d), style: const TextStyle(color: C.dim, fontSize: 12)), _kv('${catOf(evSel!.t, evSel!.c).name}${evSel!.n.isNotEmpty ? ' · ${evSel!.n}' : ''}', '${evSel!.t == 'in' ? '+' : '−'}${mny(evSel!.a)}'), _kv('Shu kun oxiridagi balans', mny(tmCalc(evSel!.d).bal))],
      ]),
      const Padding(padding: EdgeInsets.only(bottom: 10), child: Text("Balans = tanlangan sanagacha yozilgan jami daromad − jami xarajat. Modelda boshlang'ich balans saqlanmaydi, hamyonlar tarixi ham yo'q.", style: TextStyle(color: C.dim, fontSize: 12))),
      _back(),
    ]);
  }

  Widget _back() => OutlinedButton(onPressed: () => setState(() {
        mode = 'intro';
        evSel = null;
      }), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), side: const BorderSide(color: C.line), foregroundColor: C.ink), child: const Text('Boshqa sanani tanlash'));
}

/* ====================================================================== */
/*  PROFIL (premium): hub + sub-pages, Yordam, Tour                        */
/* ====================================================================== */
const String kAppVer = '1.0.0';
const Map<String, String> kMePar = {'info': 'hub', 'plan': 'hub', 'security': 'hub', 'lang': 'hub', 'cur': 'hub', 'notif': 'hub', 'theme': 'hub', 'app': 'hub', 'extra': 'hub', 'help': 'hub', 'helpc': 'help', 'faq': 'help', 'privacy': 'help', 'terms': 'help', 'contact': 'help'};
const Map<String, ({String n, Color c, String d, List<String> f})> kMeP = {
  'free': (n: 'Free', c: Color(0xFF34D399), d: 'Kundalik hisob uchun asosiy imkoniyatlar.', f: ['Oyiga 40 ta operatsiya', 'Doira diagramma va kategoriyalar', 'Oylik limit', '2 oylik tarix', '1 ta maqsad']),
  'max': (n: 'Max', c: Color(0xFF34D399), d: 'Hamma imkoniyat, cheklovsiz.', f: ['Cheksiz operatsiya va tarix', '8 ta diagramma va prognoz', 'Kategoriya limitlari', 'Cheksiz maqsadlar', 'CSV eksport']),
  'ultra': (n: 'Ultra', c: Color(0xFFA78BFA), d: 'Max + moliyaviy boshqaruv vositalari.', f: ['Max ning hamma imkoniyati', 'Bir nechta hamyon va kartalar', "Takroriy to'lovlar va eslatma", 'Qarz daftari, byudjet rejasi', 'PDF hisobot, zaxira va tiklash']),
  'biznes': (n: 'Biznes', c: Color(0xFF2DD4BF), d: 'Max + biznes hisobi va hisob-faktura.', f: ['Max ning hamma imkoniyati', 'Biznes va shaxsiy hisobni ajratish', 'Hisob-faktura yaratish va PDF', 'Mijozlar daftari', 'Foyda/zarar hisoboti va prognoz']),
  'oila': (n: 'Oila', c: Color(0xFFFB7185), d: 'Ultra + umumiy oilaviy byudjet.', f: ['Ultra ning hamma imkoniyati', "5 kishigacha oila a'zolari", 'Umumiy byudjet va maqsadlar', "Bolalar rejimi: cho'ntak puli", "A'zolar bo'yicha tahlil"]),
  'elite': (n: 'Elite', c: Color(0xFFF5D97A), d: 'Hisob yuritish emas, biznesni boshqarish uchun.', f: ['Boshqaruv paneli', 'Bir nechta kompaniya', 'Pul oqimi prognozi', 'Qarzdorlik yoshi, zararsizlik nuqtasi', 'Rahbar hisoboti (PDF)']),
};
const Map<String, String> kMeCN = {'UZS': "So'm · UZS", 'USD': 'AQSh dollari · USD', 'EUR': 'Yevro · EUR', 'RUB': 'Rubl · RUB'};

class MeTab extends StatefulWidget {
  final Future<void> Function() onSignOut;
  final ShellApi? api;
  const MeTab({super.key, required this.onSignOut, this.api});
  @override
  State<MeTab> createState() => _MeTabState();
}

class _MeTabState extends State<MeTab> {
  String page = 'hub';
  final fn = TextEditingController(), ln = TextEditingController(), ph = TextEditingController(), em = TextEditingController(), lim = TextEditingController(), msg = TextEditingController();
  final Map<String, TextEditingController> cl = {};
  final ccn = TextEditingController();
  String err = '', curSel = 'UZS', ct = '', ccType = 'out';
  String? photo; // null = unchanged, '' = removed
  bool clearSure = false;

  Profile get p => app.profile!;
  String get pk => p.isElite ? 'elite' : p.isFam ? 'oila' : p.isBiz ? 'biznes' : p.isUltra ? 'ultra' : p.isMax ? 'max' : 'free';
  bool get expired => p.plan != 'free' && !p.isMax;
  ({String t, int k}) get st => (!p.isMax && !expired) ? (t: 'Bepul tarif', k: 0) : expired ? (t: 'Muddati tugagan', k: 1) : (t: p.maxUntil > 0 ? 'Faol · ${p.daysLeft} kun qoldi' : 'Faol', k: 2);
  String get vid {
    var v = '${p.x['vid'] ?? ''}';
    if (!v.startsWith('VLT-')) {
      String r() => List.generate(4, (_) => 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'[math.Random.secure().nextInt(32)]).join();
      v = 'VLT-${r()}-${r()}';
      p.x['vid'] = v;
      app.saveProfile();
    }
    return v;
  }

  String get fullName => '${p.name} ${p.surname}'.trim();
  ImageProvider? _img(String? d) {
    try {
      if (d == null || !d.startsWith('data:image/')) return null;
      return MemoryImage(base64Decode(d.substring(d.indexOf(',') + 1)));
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    for (final c in [fn, ln, ph, em, lim, msg, ccn, ...cl.values]) {
      c.dispose();
    }
    super.dispose();
  }

  void go(String to) {
    err = '';
    if (to == 'info') {
      fn.text = p.name;
      ln.text = p.surname;
      ph.text = '${p.x['phone'] ?? ''}';
      em.text = '${p.x['email'] ?? ''}';
      photo = null;
    }
    if (to == 'cur') curSel = p.cur;
    if (to == 'app') {
      lim.text = p.limit > 0 ? '${p.limit % 1 == 0 ? p.limit.toInt() : p.limit}' : '';
      cl.clear();
      final m = p.mp('catLimits');
      for (final c in catsOf('out')) {
        final v = ((m[c.id] ?? 0) as num).toDouble();
        cl[c.id] = TextEditingController(text: v > 0 ? '${v % 1 == 0 ? v.toInt() : v}' : '');
      }
    }
    if (to == 'contact') {
      final d = p.x['contactDraft'];
      ct = d is Map && (d['t'] == 'problem' || d['t'] == 'idea') ? '${d['t']}' : '';
      msg.text = d is Map ? '${d['m'] ?? ''}' : '';
    }
    setState(() => page = to);
  }

  void back() => go(kMePar[page] ?? 'hub');

  /* ---- widgets ---- */
  Widget row(IconData ic, String t, String s, String to, {Widget? extra, bool dis = false}) => InkWell(
        onTap: dis ? null : () => go(to),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Container(width: 38, height: 38, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: C.accent.withOpacity(.1)), child: Icon(ic, size: 20, color: C.accent)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)), Text(s, style: const TextStyle(color: C.dim, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)])),
            if (extra != null) extra,
            if (!dis) const Icon(Icons.chevron_right_rounded, color: C.mute),
          ]),
        ),
      );

  Widget grp_(String t, List<Widget> rows) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(left: 4, bottom: 6), child: Text(t.toUpperCase(), style: const TextStyle(color: C.mute, fontSize: 11.5, letterSpacing: 1.2, fontWeight: FontWeight.w700))),
          Glass(padding: EdgeInsets.zero, child: Column(children: [for (var i = 0; i < rows.length; i++) ...[if (i > 0) const Divider(height: 1, color: C.line), rows[i]]])),
        ]),
      );

  Widget chip(String t, {bool ok = false, bool soon = false}) => Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: ok ? C.accent.withOpacity(.14) : const Color(0x14FFFFFF)),
        child: Text(t, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: ok ? C.accent : C.dim)),
      );

  Widget statusPill() {
    final s = st;
    final col = s.k == 2 ? C.accent : s.k == 1 ? C.warn : C.mute;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: col.withOpacity(.14)), child: Row(mainAxisSize: MainAxisSize.min, children: [CircleAvatar(radius: 3, backgroundColor: col), const SizedBox(width: 5), Text(s.t, style: TextStyle(fontSize: 11, color: col, fontWeight: FontWeight.w700))]));
  }

  Widget avatar(double r, ImageProvider? im) => Container(
        width: r * 2,
        height: r * 2,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [C.accent2, C.deep]), image: im != null ? DecorationImage(image: im, fit: BoxFit.cover) : null),
        child: im == null ? Text((p.name.isNotEmpty ? p.name[0] : 'H').toUpperCase(), style: TextStyle(fontWeight: FontWeight.w800, fontSize: r * .8, color: Colors.white)) : null,
      );

  Widget head(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [IconButton(onPressed: back, icon: const Icon(Icons.arrow_back_rounded)), Expanded(child: Text(t, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)))]),
      );

  Widget errT() => err.isEmpty ? const SizedBox.shrink() : Padding(padding: const EdgeInsets.only(top: 8), child: Text(err, style: const TextStyle(color: C.out, fontSize: 12.5)));

  Widget toggle(bool on, String t, String s, VoidCallback f) => Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontWeight: FontWeight.w700)), Text(s, style: const TextStyle(color: C.dim, fontSize: 12))])),
        Switch(value: on, activeColor: C.accent, onChanged: (_) => f()),
      ]);

  /* ---- hub ---- */
  Widget hub() {
    final k = expired ? 'free' : pk, P = kMeP[k]!;
    final pin = p.pin.isNotEmpty;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
      Glass(
        child: Column(children: [
          Row(children: [
            avatar(34, _img('${p.x['photo'] ?? ''}')),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(fullName.isEmpty ? 'Foydalanuvchi' : fullName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: vid));
                    toast(context, 'VAULT ID nusxalandi');
                  },
                  child: Row(mainAxisSize: MainAxisSize.min, children: [Text(vid, style: const TextStyle(color: C.dim, fontSize: 12.5, letterSpacing: 1)), const SizedBox(width: 4), const Icon(Icons.copy_rounded, size: 13, color: C.mute)]),
                ),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: P.c.withOpacity(.16)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.workspace_premium_rounded, size: 13, color: P.c), const SizedBox(width: 4), Text(P.n, style: TextStyle(fontSize: 11, color: P.c, fontWeight: FontWeight.w800))])),
                  statusPill(),
                ]),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          uBtn('Profilni tahrirlash', () => go('info'), ghost: true),
        ]),
      ),
      const SizedBox(height: 12),
      Glass(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(Icons.workspace_premium_rounded, color: P.c), const SizedBox(width: 10), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Joriy tarif', style: TextStyle(color: C.dim, fontSize: 11.5)), Text(P.n, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17))]), const Spacer(), statusPill()]),
          const SizedBox(height: 8),
          Text(P.d, style: const TextStyle(color: C.dim, fontSize: 13)),
          const SizedBox(height: 10),
          uBtn('Tarif va obuna', () => go('plan'), ghost: true),
        ]),
      ),
      grp_('Hisob', [
        row(Icons.person_rounded, "Shaxsiy ma'lumotlar", '${p.x['phone'] ?? ''}'.isNotEmpty ? '${p.x['phone']}' : ('${p.x['email'] ?? ''}'.isNotEmpty ? '${p.x['email']}' : 'Ism, telefon, email, rasm'), 'info'),
        row(Icons.workspace_premium_rounded, 'Tarif va obuna', '${P.n} · ${st.t}', 'plan'),
        row(Icons.shield_rounded, 'Xavfsizlik', pin ? 'PIN yoqilgan' : "PIN o'rnatilmagan", 'security', extra: chip(pin ? 'Himoyalangan' : 'Ochiq', ok: pin)),
      ]),
      grp_('Sozlamalar', [
        row(Icons.language_rounded, 'Til', const {'uz': "O'zbek", 'en': 'English', 'ru': 'Русский'}[app.lang] ?? '', 'lang'),
        row(Icons.paid_rounded, 'Asosiy valyuta', kMeCN[p.cur] ?? p.cur, 'cur'),
        row(Icons.notifications_rounded, 'Bildirishnomalar', p.x['nOff'] == true ? "O'chirilgan" : 'Yoqilgan', 'notif'),
        row(Icons.dark_mode_rounded, "Ko'rinish", "Qorong'i rejim", 'theme'),
        row(Icons.settings_rounded, 'Ilova sozlamalari', 'Limitlar, ma\'lumotlar, balans', 'app'),
        row(Icons.category_rounded, 'Kategoriyalar', "O'z kategoriyalaringiz", 'extra'),
      ]),
      grp_('Yordam', [row(Icons.help_outline_rounded, 'Yordam va aloqa', 'Yordam markazi, FAQ, murojaat', 'help')]),
      const SizedBox(height: 22),
      Center(child: Text('VAULT · FROM EIGHTEEN', style: const TextStyle(color: C.gold, letterSpacing: 3, fontSize: 11.5, fontWeight: FontWeight.w600))),
      const Center(child: Padding(padding: EdgeInsets.only(top: 4), child: Text('Versiya $kAppVer', style: TextStyle(color: C.mute, fontSize: 11)))),
      const SizedBox(height: 12),
      uBtn('Chiqish', _logout, ghost: true),
      const Padding(padding: EdgeInsets.only(top: 8), child: Text("Chiqish ilovani qulflaydi va hisobdan chiqaradi. Ma'lumotlar shu qurilmada saqlanib qoladi.", style: TextStyle(color: C.mute, fontSize: 11.5), textAlign: TextAlign.center)),
    ]);
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        backgroundColor: C.bg2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: C.line)),
        content: Text(t('signOutQ')),
        actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: Text(t('cancel'), style: const TextStyle(color: C.dim))), TextButton(onPressed: () => Navigator.pop(d, true), child: Text(t('yes'), style: const TextStyle(color: C.out, fontWeight: FontWeight.w800)))],
      ),
    );
    if (ok == true) await widget.onSignOut();
  }

  /* ---- pages ---- */
  Widget infoP() {
    final cur = photo == null ? _img('${p.x['photo'] ?? ''}') : (photo!.isEmpty ? null : _img(photo));
    final has = cur != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      head("Shaxsiy ma'lumotlar"),
      Center(child: avatar(46, cur)),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        TextButton(onPressed: _pick, child: const Text('Rasm tanlash')),
        if (has) TextButton(onPressed: () => setState(() => photo = ''), child: const Text("O'chirish", style: TextStyle(color: C.out))),
      ]),
      uCard('Profil', children: [
        uField(fn, 'Ism'),
        const SizedBox(height: 8),
        uField(ln, 'Familiya'),
        const SizedBox(height: 8),
        uField(ph, 'Telefon (ixtiyoriy)', kt: TextInputType.phone),
        const SizedBox(height: 8),
        uField(em, 'Email (ixtiyoriy)', kt: TextInputType.emailAddress),
        const SizedBox(height: 8),
        Row(children: [const Text('VAULT ID: ', style: TextStyle(color: C.dim)), Text(vid, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1))]),
        errT(),
        const SizedBox(height: 10),
        uBtn('Saqlash', _saveInfo),
      ]),
    ]);
  }

  Future<void> _pick() async {
    try {
      final f = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 256, maxHeight: 256, imageQuality: 82);
      if (f == null) return;
      final b = await f.readAsBytes();
      setState(() => photo = 'data:image/jpeg;base64,${base64Encode(b)}');
    } catch (_) {
      if (mounted) toast(context, "Rasmni o'qib bo'lmadi. Boshqa rasm tanlang.");
    }
  }

  Future<void> _saveInfo() async {
    final f = fn.text.trim().replaceAll(RegExp(r'\s+'), ' '), l = ln.text.trim().replaceAll(RegExp(r'\s+'), ' '), phn = ph.text.trim(), eml = em.text.trim();
    String? e;
    if (f.length < 2) {
      e = 'Ism kamida 2 harf bo\'lsin.';
    } else if ('$f $l'.trim().length > 40) {
      e = 'Ism va familiya jami 40 belgidan oshmasin.';
    } else if (phn.isNotEmpty && (!RegExp(r'^\+?[0-9\s\-()]+$').hasMatch(phn) || phn.replaceAll(RegExp(r'\D'), '').length < 7 || phn.replaceAll(RegExp(r'\D'), '').length > 15)) {
      e = "Telefon raqamini to'g'ri kiriting.";
    } else if (eml.isNotEmpty && !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(eml)) {
      e = "Email manzilini to'g'ri kiriting.";
    }
    if (e != null) return setState(() => err = e!);
    p.name = f;
    p.surname = l;
    p.x['phone'] = phn;
    p.x['email'] = eml;
    if (photo != null) {
      if (photo!.isEmpty) {
        p.x.remove('photo');
      } else {
        p.x['photo'] = photo;
      }
    }
    await app.saveProfile();
    if (mounted) {
      setState(() => err = '');
      toast(context, 'Saqlandi');
    }
  }

  Widget planP() {
    final k = expired ? 'free' : pk, P = kMeP[k]!;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      head('Tarif va obuna'),
      Glass(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(Icons.workspace_premium_rounded, color: P.c, size: 28), const SizedBox(width: 10), Text(P.n, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)), const Spacer(), statusPill()]),
          const SizedBox(height: 8),
          Text(P.d, style: const TextStyle(color: C.dim)),
          const SizedBox(height: 10),
          for (final f in P.f) Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [Icon(Icons.check_rounded, size: 18, color: P.c), const SizedBox(width: 8), Expanded(child: Text(f))])),
          const SizedBox(height: 8),
          uBtn(p.isMax ? 'Tarifni almashtirish' : expired ? 'Tarifni yangilash' : "Max ga o'tish", () => widget.api?.show('plans')),
        ]),
      ),
      const SizedBox(height: 12),
      uCard('Obuna', children: [
        URow(title: 'Tarif', amount: P.n),
        URow(title: 'Obuna holati', amount: st.t),
        if (p.isMax && p.maxUntil > 0) URow(title: 'Tugash sanasi', amount: dayKey(DateTime.fromMillisecondsSinceEpoch(p.maxUntil))),
        if (expired && p.maxUntil > 0) URow(title: 'Tugagan sana', amount: dayKey(DateTime.fromMillisecondsSinceEpoch(p.maxUntil))),
        uSmall("Barcha tariflar va ularning imkoniyatlari «Tariflar» sahifasida. Tarif almashtirish mavjud to'lov oqimi orqali bajariladi."),
      ]),
    ]);
  }

  Widget securityP() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        head('Xavfsizlik'),
        const PinTile(),
        const SizedBox(height: 12),
        uCard('Kirish xavfsizligi', children: [
          URow(title: 'Kirish usuli', amount: p.pin.isNotEmpty ? 'PIN kod' : 'Himoyasiz'),
          URow(title: 'Avto-qulflash', amount: p.pin.isNotEmpty ? "30 soniyadan so'ng" : "O'chiq (PIN kerak)"),
          const URow(title: 'Xato urinishlar', amount: "5 tadan keyin 30 soniya kutish"),
        ]),
        uCard('Faol seanslar', children: [
          URow(title: 'Bu qurilma', sub: 'Hozir faol', amount: 'Faol'),
          uSmall("VAULT hozircha qurilmaga bog'langan hisob bilan ishlaydi, shuning uchun faqat joriy qurilma ko'rsatiladi."),
        ]),
        uCard('Xavfsizlik haqida', children: [
          uSmall("• PIN ochiq holda saqlanmaydi va ekranda ko'rsatilmaydi.\n• Ilovani boshqalar qo'lida qoldirmang, PIN o'rnating.\n• Ilova ma'lumotlarini tozalash mahalliy ma'lumotlarni o'chirib yuboradi."),
        ]),
      ]);

  Widget langP() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        head('Til'),
        for (final l in const [('uz', 'Oʻzbekcha'), ('en', 'English'), ('ru', 'Русский')])
          Padding(padding: const EdgeInsets.only(bottom: 8), child: Glass(padding: EdgeInsets.zero, child: ListTile(title: Text(l.$2, style: const TextStyle(fontWeight: FontWeight.w700)), trailing: app.lang == l.$1 ? const Icon(Icons.check_circle_rounded, color: C.accent) : null, onTap: () async {
                await app.changeLang(l.$1);
                if (mounted) setState(() {});
              }))),
      ]);

  Widget curP() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        head('Asosiy valyuta'),
        for (final k in kCurd.keys)
          Padding(padding: const EdgeInsets.only(bottom: 6), child: Glass(padding: EdgeInsets.zero, child: ListTile(dense: true, leading: SizedBox(width: 38, child: Text(curUnit(k), style: const TextStyle(fontWeight: FontWeight.w800))), title: Text(kMeCN[k] ?? k), trailing: curSel == k ? const Icon(Icons.check_circle_rounded, color: C.accent) : null, onTap: () => setState(() => curSel = k)))),
        const SizedBox(height: 8),
        uBtn('Saqlash', () async {
          await app.setCur(curSel);
          if (mounted) {
            setState(() {});
            toast(context, 'Valyuta saqlandi');
          }
        }),
      ]);

  Widget notifP() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        head('Bildirishnomalar'),
        Glass(child: Column(children: [
          toggle(p.x['nOff'] != true, 'Bildirishnomalar', 'Oylik limit ogohlantirishlari (80% va 100%) hamda eslatmalar.', () async {
            p.x['nOff'] = p.x['nOff'] != true;
            await app.saveProfile();
            setState(() {});
          }),
        ])),
      ]);

  Widget themeP() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        head("Ko'rinish"),
        Glass(padding: EdgeInsets.zero, child: const ListTile(leading: Icon(Icons.dark_mode_rounded, color: C.accent), title: Text("Qorong'i", style: TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('Faol'), trailing: Icon(Icons.check_circle_rounded, color: C.accent))),
        const SizedBox(height: 8),
        Glass(padding: EdgeInsets.zero, child: const ListTile(enabled: false, leading: Icon(Icons.light_mode_rounded), title: Text("Yorug'"), subtitle: Text('Tez orada'))),
        const Padding(padding: EdgeInsets.all(8), child: Text("VAULT premium qorong'i ko'rinishda ishlaydi. Yorug' rejim keyingi yangilanishlarda qo'shiladi.", style: TextStyle(color: C.dim, fontSize: 12))),
      ]);

  Widget appP() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        head('Ilova sozlamalari'),
        uCard('Oylik limit', children: [
          uSmall('Oylik umumiy xarajat limiti. Bo\'sh qoldirsangiz limit o\'chadi.'),
          uField(lim, 'Limit, ${curUnit()}', num: true),
        ]),
        if (!p.isMax)
          uCard('Kategoriya limitlari · Max', children: [uSmall("Har bir kategoriya uchun oylik limit qo'yib, qaysi biri oshib ketganini Tahlil bo'limida ko'rasiz."), uBtn('Max bilan ochish', () => widget.api?.show('plans'))])
        else
          uCard('Kategoriya limitlari · Max', children: [for (final c in catsOf('out')) Padding(padding: const EdgeInsets.only(bottom: 8), child: uField(cl.putIfAbsent(c.id, () => TextEditingController()), '${c.name} limiti', num: true))]),
        errT(),
        const SizedBox(height: 8),
        uBtn('Saqlash', _saveLim),
        const SizedBox(height: 12),
        uCard("Ma'lumotlar", children: [
          uSmall("Ma'lumotlar faqat shu qurilmada saqlanadi. Ilova o'chirilsa yoki ma'lumotlari tozalansa yo'qoladi."),
          SureBtn(label: "Barcha operatsiyalarni o'chirish", onSure: () async {
            for (final x in List<Tx>.from(app.txs)) {
              await app.removeTx(x.id);
            }
            if (mounted) toast(context, "Hammasi o'chirildi");
          }),
        ]),
      ]);

  Future<void> _saveLim() async {
    final l = lim.text.trim().isEmpty ? 0.0 : parseAmount(lim.text);
    if (l == null || l < 0) return setState(() => err = 'Limitni raqam bilan kiriting.');
    final m = <String, dynamic>{};
    if (p.isMax) {
      for (final e in cl.entries) {
        final v = e.value.text.trim().isEmpty ? 0.0 : parseAmount(e.value.text);
        if (v == null || v < 0) return setState(() => err = "Kategoriya limitlari raqam bo'lishi kerak.");
        if (v > 0) m[e.key] = v;
      }
      p.x['catLimits'] = m;
    }
    p.limit = l;
    await app.saveProfile();
    if (mounted) {
      setState(() => err = '');
      toast(context, 'Saqlandi');
    }
  }

  Widget extraP() {
    final cc = p.x['cc'] is Map ? Map<String, dynamic>.from(p.x['cc'] as Map) : <String, dynamic>{};
    final list = cc[ccType] is List ? List.from(cc[ccType] as List) : [];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      head('Kategoriyalar'),
      if (!p.isMax)
        uCard('O\'z kategoriyalaringiz · Max', children: [uSmall("O'zingizning kirim va chiqim kategoriyalaringizni yarating."), uBtn('Max bilan ochish', () => widget.api?.show('plans'))])
      else ...[
        Row(children: [for (final e in const [('out', 'Chiqim'), ('in', 'Kirim')]) Expanded(child: Padding(padding: EdgeInsets.only(right: e.$1 == 'out' ? 8 : 0), child: ChoiceChip(label: Center(child: Text(e.$2)), selected: ccType == e.$1, onSelected: (_) => setState(() => ccType = e.$1))))]),
        const SizedBox(height: 10),
        uCard("Yangi kategoriya", children: [
          uField(ccn, 'Nomi', max: 20),
          const SizedBox(height: 10),
          uBtn("Qo'shish", () async {
            final n = ccn.text.trim();
            if (n.length < 2) return toast(context, 'Nom kamida 2 harf bo\'lsin.');
            if (list.length >= 12) return toast(context, "Eng ko'pi 12 ta.");
            list.add(['cc_${newId()}', n, kCCol[list.length % kCCol.length]]);
            cc[ccType] = list;
            p.x['cc'] = cc;
            ccn.clear();
            await app.saveProfile();
            if (mounted) setState(() {});
          }),
        ]),
        for (final c in list)
          if (c is List && c.length >= 3)
            URow(title: '${c[1]}', action: SureBtn(onSure: () async {
              list.remove(c);
              cc[ccType] = list;
              p.x['cc'] = cc;
              await app.saveProfile();
              if (mounted) setState(() {});
            })),
        if (list.isEmpty) uSmall("Hozircha o'z kategoriyangiz yo'q."),
      ],
    ]);
  }

  Widget helpP() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        head('Yordam va aloqa'),
        grp_('Yordam', [row(Icons.menu_book_rounded, 'Yordam markazi', "Qo'llanma va maslahatlar", 'helpc'), row(Icons.question_answer_rounded, "Ko'p so'raladigan savollar", 'FAQ', 'faq')]),
        grp_('Huquqiy', [row(Icons.lock_rounded, 'Maxfiylik siyosati', "Ma'lumotlaringiz qanday saqlanadi", 'privacy'), row(Icons.description_rounded, 'Foydalanish shartlari', 'Xizmatdan foydalanish qoidalari', 'terms')]),
        grp_('Aloqa', [row(Icons.chat_rounded, 'Asoschiga murojaat', 'Muammo yoki taklif yuborish', 'contact', extra: chip('Qoralama', soon: true))]),
      ]);

  Widget textP(String title, List<(String, String)> secs) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        head(title),
        for (final s in secs) uCard(s.$1, children: [uSmall(s.$2)]),
      ]);

  Widget helpcP() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        head('Yordam markazi'),
        uCard("Qo'llanma", children: [uSmall("VAULT bo'limlari bilan qisqa interaktiv qo'llanma orqali yana tanishing."), uBtn("Qo'llanmani qayta boshlash", () => showTour(context))]),
        uCard('Tezkor maslahatlar', children: [uSmall("• Operatsiya qo'shish uchun pastdagi «+» tugmasidan foydalaning.\n• Oylik limit qo'ysangiz, 80% va 100% ga yetganda ogohlantirish olasiz.\n• PIN o'rnatish: Profil → Xavfsizlik.")]),
      ]);

  Widget contactP() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        head('Asoschiga murojaat'),
        uCard('Murojaat turi', children: [
          Row(children: [for (final e in const [('problem', 'Muammo'), ('idea', 'Taklif')]) Expanded(child: Padding(padding: EdgeInsets.only(right: e.$1 == 'problem' ? 8 : 0), child: ChoiceChip(label: Center(child: Text(e.$2)), selected: ct == e.$1, onSelected: (_) => setState(() => ct = e.$1))))]),
          const SizedBox(height: 10),
          TextField(controller: msg, maxLines: 5, maxLength: 1000, decoration: const InputDecoration(hintText: 'Xabaringiz')),
          uSmall("Xabar yuborish xizmati hali ulanmagan va keyingi bosqichda ishga tushadi. Hozircha yozganingiz shu qurilmada qoralama sifatida saqlanadi."),
          errT(),
          uBtn('Qoralamani saqlash', () async {
            if (ct.isEmpty) return setState(() => err = 'Murojaat turini tanlang.');
            if (msg.text.trim().length < 10) return setState(() => err = "Xabar kamida 10 belgidan iborat bo'lsin.");
            p.x['contactDraft'] = {'t': ct, 'm': msg.text.trim()};
            await app.saveProfile();
            if (mounted) {
              setState(() => err = '');
              toast(context, 'Qoralama saqlandi. Yuborish keyingi bosqichda yoqiladi.');
            }
          }),
        ]),
      ]);

  @override
  Widget build(BuildContext context) {
    if (page == 'hub') return hub();
    final body = switch (page) {
      'info' => infoP(),
      'plan' => planP(),
      'security' => securityP(),
      'lang' => langP(),
      'cur' => curP(),
      'notif' => notifP(),
      'theme' => themeP(),
      'app' => appP(),
      'extra' => extraP(),
      'help' => helpP(),
      'helpc' => helpcP(),
      'faq' => textP("Ko'p so'raladigan savollar", const [
          ("Ma'lumotlarim qayerda saqlanadi?", "Faqat shu qurilmada. Ilova ma'lumotlari tozalansa, mahalliy ma'lumotlar yo'qolishi mumkin."),
          ("PIN kodni qanday o'rnataman yoki o'zgartiraman?", "Profil → Xavfsizlik bo'limida PIN o'rnatish, o'zgartirish yoki o'chirish mumkin."),
          ('Tarifni qanday almashtiraman?', "Profil → Tarif va obuna → Tariflar sahifasidan kerakli tarifni tanlang."),
          ("Valyutani o'zgartirsam, operatsiyalarim o'zgaradimi?", "Yo'q. Faqat summalar ko'rsatiladigan belgi o'zgaradi, kiritilgan raqamlar qayta hisoblanmaydi."),
          ("Muammo yoki taklif bo'lsa nima qilaman?", "Profil → Yordam va aloqa → «Asoschiga murojaat» bo'limidan foydalaning."),
        ]),
      'privacy' => textP('Maxfiylik siyosati', const [
          ("Qanday ma'lumotlar saqlanadi", "Siz kiritgan operatsiyalar, maqsadlar, kartalar, profil ma'lumotlari (ism, ixtiyoriy telefon va email, rasm) va sozlamalar."),
          ('Qayerda saqlanadi', "Shu qurilmadagi ilova xotirasida. Ilova ma'lumotlari tozalansa, mahalliy ma'lumotlar yo'qolishi mumkin."),
          ('PIN kod', "PIN ochiq holda saqlanmaydi va hech qayerda ko'rsatilmaydi."),
          ('Uchinchi shaxslar', "Ma'lumotlaringiz sotilmaydi."),
          ('Aloqa', 'Savollar uchun: Profil → Yordam va aloqa → Asoschiga murojaat.'),
        ]),
      'terms' => textP('Foydalanish shartlari', const [
          ('Xizmat haqida', "VAULT shaxsiy moliyani kuzatish uchun vosita. U bank yoki moliyaviy maslahat xizmati emas."),
          ("Ma'lumotlar uchun javobgarlik", "Kiritilgan ma'lumotlarning to'g'riligi sizning zimmangizda. Ma'lumotlarni zaxiralab turish tavsiya etiladi."),
          ('Tariflar', "Pullik tariflar tanlangan muddat davomida amal qiladi. Narxlar va imkoniyatlar Tariflar sahifasida ko'rsatilgan."),
          ('Foydalanish qoidalari', "Ilovadan qonunga zid maqsadlarda foydalanish, xizmat ishiga xalaqit berish taqiqlanadi."),
          ("O'zgartirishlar", "Shartlar yangilanishi mumkin. Joriy versiya shu bo'limda ko'rsatiladi."),
        ]),
      'contact' => contactP(),
      _ => const SizedBox.shrink(),
    };
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) back();
      },
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [body]),
    );
  }
}

/* ---------------------------- TOUR ---------------------------- */
const List<(IconData, String, String)> kTour = [
  (Icons.home_rounded, 'Bosh sahifa', "VAULT'ga xush kelibsiz! Bu yerda barcha moliyaviy holatingizni bir joyda boshqarishingiz mumkin."),
  (Icons.credit_card_rounded, 'Balans va virtual karta', "Bu yerda hisobingiz va VAULT virtual kartangizni ko'rasiz. Kartangizni boshqarishingiz mumkin."),
  (Icons.south_west_rounded, 'Kirim', 'Daromadingizni qayd etish uchun Kirim tugmasidan foydalaning.'),
  (Icons.north_east_rounded, 'Chiqim', "Xarajatlaringizni yozib boring va pulingiz qayerga sarflanayotganini kuzating."),
  (Icons.flag_rounded, 'Maqsadlar', "Jamg'arma maqsadini yarating va unga erishish jarayonini kuzating."),
  (Icons.bar_chart_rounded, 'Tahlil', "Moliyaviy statistikangiz orqali kirim va chiqimlaringizni tahlil qiling."),
  (Icons.check_rounded, 'Hammasi tayyor', "Ajoyib! Endi VAULT'dan foydalanishni boshlashingiz mumkin."),
];

Future<void> tourMark(bool skip, bool auto) async {
  final p = app.profile;
  if (p == null) return;
  p.x['tour'] = {'v': 1, 'done': skip ? 0 : 1, 'skip': skip ? 1 : 0, 'auto': auto ? 1 : 0, 'at': DateTime.now().millisecondsSinceEpoch};
  await app.saveProfile();
}

/// First-run auto tour: only for brand-new, empty accounts.
void tourAuto(BuildContext context) {
  final p = app.profile;
  if (p == null || p.isElite) return;
  final t0 = p.x['tour'];
  if (t0 is Map && ((t0['v'] ?? 0) as num) >= 1) return;
  if (app.txs.length >= 3) {
    tourMark(true, true);
    return;
  }
  showTour(context, auto: true);
}

Future<void> showTour(BuildContext context, {bool auto = false}) => showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (d) => _TourDlg(auto: auto),
    );

class _TourDlg extends StatefulWidget {
  final bool auto;
  const _TourDlg({required this.auto});
  @override
  State<_TourDlg> createState() => _TourDlgState();
}

class _TourDlgState extends State<_TourDlg> {
  int i = 0;
  @override
  Widget build(BuildContext context) {
    final s = kTour[i], last = i == kTour.length - 1;
    return Dialog(
      backgroundColor: C.bg2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: C.line)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            for (var k = 0; k < kTour.length; k++) Container(width: k == i ? 18 : 7, height: 7, margin: const EdgeInsets.only(right: 5), decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: k == i ? C.accent : k < i ? C.accent.withOpacity(.5) : C.line)),
            const Spacer(),
            if (!last) TextButton(onPressed: () => _close(true), child: const Text("O'tkazib yuborish", style: TextStyle(color: C.dim, fontSize: 12))),
          ]),
          const SizedBox(height: 16),
          if (i == 0) const VaultLogo(size: 64) else Container(width: 64, height: 64, decoration: BoxDecoration(shape: BoxShape.circle, color: C.accent.withOpacity(.12), border: Border.all(color: C.accent.withOpacity(.4))), child: Icon(s.$1, color: C.accent, size: 30)),
          const SizedBox(height: 14),
          Text(s.$2, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(s.$3, style: const TextStyle(color: C.dim, height: 1.4), textAlign: TextAlign.center),
          const SizedBox(height: 18),
          Row(children: [
            Text('${i + 1} / ${kTour.length}', style: const TextStyle(color: C.mute, fontSize: 12)),
            const Spacer(),
            if (i > 0) TextButton(onPressed: () => setState(() => i--), child: const Text('Orqaga')),
            FilledButton(onPressed: () => last ? _close(false) : setState(() => i++), child: Text(last ? 'Boshlash' : 'Keyingi')),
          ]),
        ]),
      ),
    );
  }

  void _close(bool skip) {
    tourMark(skip, widget.auto);
    Navigator.pop(context);
  }
}

/* ===== STUBS: replaced one by one by real modules (remove the stub when its module is written) ===== */
class ModuleSoon extends StatelessWidget {
  final String name;
  const ModuleSoon(this.name, {super.key});
  @override
  Widget build(BuildContext context) => Center(child: Text(name, style: const TextStyle(color: C.dim)));
}

Widget buildModule(String k, ShellApi api) {
  switch (k) {
    case 'ultra':
      return UltraTab(api: api);
    case 'biz':
      return BizTab(api: api);
    case 'oila':
      return OilaTab(api: api);
    case 'elite':
      return EliteTab(api: api);
    case 'time':
      return TimeTab(api: api);
    case 'nexus':
      return NexusTab(api: api);
    case 'genesis':
      return GenesisTab(api: api);
    case 'orbit':
      return OrbitTab(api: api);
    case 'empire':
      return EmpireTab(api: api);
    case 'ehson':
      return EhsonTab(api: api);
    default:
      return ModuleSoon(secLabel(k));
  }
}
