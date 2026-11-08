# The Olive Branch 🕊️📰

A customizable, distraction-free news aggregator built with Flutter Web. Curates and aggregates feeds across diverse publications with persistent user preferences, dynamic theming, and an anti-CORS Nginx proxy.

Visit the live app: [theolivebranch.press](https://theolivebranch.press)

---

## ✨ Features

- **Multi-Feed Aggregation**: Consumes, parses, and normalizes RSS and Atom feeds into a single, clean chronological or category-filtered reading interface.
- **Custom Theming Engine**: User-selectable seed colors, dark mode, light mode, and typography powered by Google Fonts (Merriweather and Lato).
- **CORS Bypass via Nginx Reverse Proxy**: Integrates with a dedicated `/proxy/` Nginx location block with DNS resolution caching to deliver fast, reliable feed fetching without client-side cross-origin errors.
- **Persistent Preferences**: Saves active feeds, color choices, and layout density across browser sessions.

---

## 🛠️ Architecture

- **Frontend**: Flutter Web (Dart 3)
- **State Management**: Provider (`ChangeNotifierProvider`)
- **Backend / Delivery**: Hardened Nginx reverse proxy on GCP e2-micro via WE-IAC, terminating TLS 1.3 via Certbot.

---

## 🚀 Getting Started

### Development
```bash
flutter pub get
flutter run -d chrome
```

### Production Build
```bash
flutter build web --release
```

Output is generated at `build/web/`.

---

## 📄 License

MIT License. Designed and developed by Archer Woods.
