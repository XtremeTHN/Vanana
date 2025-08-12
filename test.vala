void main () {
    // set locale from environment so printf's grouping uses the user's locale
    Intl.setlocale (LocaleCategory.ALL, "");

    int64 value = 1234567890;
    // build format string using the platform-correct int64 format macro
    string fmt = "%'" + int64.FORMAT; // e.g. "%'lld" on many systems
    // produce a locale-grouped string
    string grouped = fmt.printf( value);
    print("locale grouped: %s\n", grouped);
}