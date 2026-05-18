/// BBZCloud Mobile - Global Navigator Keys
///
/// Erlaubt Services ohne BuildContext (Bridges, Push-Handler, ...)
/// Routen zu pushen oder Dialoge anzuzeigen.

import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>();
