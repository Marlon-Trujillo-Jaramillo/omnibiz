package com.omnibiz.pos

import io.flutter.embedding.android.FlutterFragmentActivity

// local_auth (huella / rostro) necesita una FragmentActivity para mostrar el
// diálogo biométrico del sistema; con FlutterActivity falla en silencio.
class MainActivity : FlutterFragmentActivity()
