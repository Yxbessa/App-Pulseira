# Diagnóstico Técnico — App Pulseira

**Status:** Código Dart está correto. Os problemas estão na camada Android e na configuração do Firebase.

---

## 🔴 CRÍTICOS (3)

### 1. `flutter.ndkVersion` retorna Provider vazio — build abortado
**Arquivo:** `android/app/build.gradle.kts`, linha 10

O Firebase Firestore compila código nativo C++ e precisa do NDK. `flutter.ndkVersion` é um Provider do Gradle que chega nulo quando o Firebase tenta ler. Esse é exatamente o erro _"Cannot query the value of this provider because it has no value available"_.

**Fix:**
```kotlin
// ANTES
ndkVersion = flutter.ndkVersion

// DEPOIS
ndkVersion = "27.0.12077973"
```

Adicionar dentro de `compileOptions` e `dependencies`:
```kotlin
isCoreLibraryDesugaringEnabled = true

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

> A pasta `Android_Quebrado/` do projeto já tem essa versão corrigida.

---

### 2. Firebase `appId` com plataforma errada (`:web:` em vez de `:android:`)
**Arquivo:** `lib/main.dart`, linha 17

```dart
// ERRADO — é o ID do app Web
appId: '1:999050142406:web:a662eee5b930215601edc7',
```

O `:web:` no meio indica que foi copiado o ID do app **Web** registrado no Firebase Console, não o Android. O Firebase SDK usará o contexto de plataforma errado.

**Fix:** Firebase Console → Configurações do projeto → app Android → copie o "ID do app" (tem `:android:` no meio).

```dart
// CERTO
appId: '1:999050142406:android:XXXXXXXXXXXXXXXX',
```

---

### 3. AndroidManifest sem nenhuma permissão de Bluetooth
**Arquivo:** `android/app/src/main/AndroidManifest.xml`

O arquivo não declara nenhuma permissão. O app compila, mas trava silenciosamente ao tentar escanear BLE. O `flutter_local_notifications` também precisa de `POST_NOTIFICATIONS` no Android 13+.

**Fix — adicionar antes de `<application>`:**
```xml
<!-- Bluetooth (API < 31) -->
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />

<!-- Bluetooth (API 31+) -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"
    android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />

<!-- Localização — obrigatória para BLE scan -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Notificações (Android 13+) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.VIBRATE" />
```

---

## 🟡 ALTOS (2)

### 4. Gradle 9.1.0 + AGP 9.0.1 — versões experimentais demais
**Arquivos:** `android/settings.gradle.kts` e `android/gradle/wrapper/gradle-wrapper.properties`

O Gradle 9.x tem "strict mode" que bloqueia injeções de configuração que o Flutter ainda faz internamente.

**Fix em `settings.gradle.kts`:**
```kotlin
// ANTES
id("com.android.application") version "9.0.1" apply false
id("org.jetbrains.kotlin.android") version "2.3.20" apply false

// DEPOIS
id("com.android.application") version "8.7.3" apply false
id("org.jetbrains.kotlin.android") version "2.1.0" apply false
```

**Fix em `android/gradle/wrapper/gradle-wrapper.properties`:**
```
distributionUrl=https\://services.gradle.org/distributions/gradle-8.10.2-all.zip
```

---

### 5. `compileSdk`, `minSdk`, `targetSdk` via Provider — mesma raiz do problema 1
**Arquivo:** `android/app/build.gradle.kts`, linhas 9, 20–21

```kotlin
// ANTES
compileSdk = flutter.compileSdkVersion
minSdk = flutter.minSdkVersion
targetSdk = flutter.targetSdkVersion
versionCode = flutter.versionCode
versionName = flutter.versionName

// DEPOIS
compileSdk = 35
minSdk = 24        // mínimo para flutter_blue_plus
targetSdk = 35
versionCode = 1
versionName = "1.0"
```

---

## 🟢 MÉDIO (1)

### 6. `android.newDsl=false` conflita com arquivos `.kts`
**Arquivo:** `android/gradle.properties`

O projeto usa Kotlin DSL (`.kts`) mas desativa o novo DSL com essa flag — contraditório.

**Fix:**
```properties
# Remover estas duas linhas:
android.newDsl=false
android.builtInKotlin=false

# Manter:
org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=2G
android.useAndroidX=true
```

> O valor original `-Xmx8G` é excessivo. `4G` é suficiente e evita falhas em máquinas com menos RAM disponível.

---

## Plano de execução (ordem importa)

```bash
# 1. Limpar caches sujos das duas versões de Gradle
cd android && ./gradlew clean
rm -rf ~/.gradle/caches/
rm -rf .gradle/

# 2. Copiar os arquivos corrigidos da pasta Android_Quebrado
cp Android_Quebrado/app/build.gradle.kts android/app/build.gradle.kts
cp Android_Quebrado/settings.gradle.kts android/settings.gradle.kts
cp Android_Quebrado/gradle.properties android/gradle.properties

# 3. Ajustar o gradle wrapper manualmente
# Arquivo: android/gradle/wrapper/gradle-wrapper.properties
# Trocar: gradle-9.1.0-all.zip → gradle-8.10.2-all.zip

# 4. Adicionar permissões no AndroidManifest.xml
# Arquivo: android/app/src/main/AndroidManifest.xml
# Colar o bloco de <uses-permission> antes de <application>

# 5. Corrigir o appId no main.dart
# Arquivo: lib/main.dart, linha 17
# Pegar o ID correto no Firebase Console (com :android: no meio)

# 6. Testar o build
cd ..
flutter clean && flutter pub get
flutter run --verbose
```

---

## Resumo

| # | Severidade | Problema | Arquivo |
|---|-----------|----------|---------|
| 1 | 🔴 Crítico | `flutter.ndkVersion` retorna Provider vazio | `android/app/build.gradle.kts` |
| 2 | 🔴 Crítico | Firebase `appId` com `:web:` em vez de `:android:` | `lib/main.dart` |
| 3 | 🔴 Crítico | Sem permissões Bluetooth no AndroidManifest | `android/.../AndroidManifest.xml` |
| 4 | 🟡 Alto | Gradle 9.1.0 + AGP 9.0.1 muito novos/estritos | `settings.gradle.kts` + wrapper |
| 5 | 🟡 Alto | SDK versions via Provider instável | `android/app/build.gradle.kts` |
| 6 | 🟢 Médio | `android.newDsl=false` conflita com KTS | `android/gradle.properties` |

**Nota:** A pasta `Android_Quebrado/` do projeto já resolve os problemas 1, 4 e 5. Faltou ela ser ativada. Os problemas 2 (appId) e 3 (permissões) precisam de correção manual.