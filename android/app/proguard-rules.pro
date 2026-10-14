# google_mlkit_text_recognition references the Chinese, Devanagari, Japanese
# and Korean recognisers, which ship as separate optional libraries. The app
# only reads Latin text (passports), so they are not bundled; tell R8 not to
# fail the release build over them.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
