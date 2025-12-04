import 'package:flutter/material.dart';

import 'colors.dart';

/// This file contains the constants used in the application.
/// It's useful for centralization and easy maintenance.

const String facebookUrl = 'https://www.facebook.com/';
const String instagramUrl = 'https://www.instagram.com/';
const String linkedinUrl = 'https://www.linkedin.com/';
const String xUrl = 'https://x.com/';

const String defaultPrefix = '+216';
const String defaultIsoCode = 'TN';

BorderRadius circularRadius = BorderRadius.circular(100);
BorderRadius regularRadius = BorderRadius.circular(12);
BorderRadius smallRadius = BorderRadius.circular(8);

Border lightBorder = Border.all(color: kNeutralLightColor, width: 0.7);
Border regularBorder = Border.all(color: kNeutralOpacityColor, width: 0.8);
Border regularPrimaryBorder = Border.all(color: kPrimaryColor, width: 1);
Border regularErrorBorder = Border.all(color: kErrorColor, width: 0.8);

// Define when screens adabt Mobile version UI
const double kMobileMaxWidth = 500;

// Default app theme
const ThemeMode defaultTheme = ThemeMode.dark;

// Default Locale
const Locale defaultLocale = Locale('en', 'US');

const minPasswordNumberOfCharacters = 6;

// Colors list for the auto complete text field
const colorSuggestions = [
  'red',
  'orange',
  'yellow',
  'green',
  'blue',
  'purple',
  'pink',
  'brown',
  'black',
  'white',
  'gray',
  'beige',
  'cyan',
  'magenta',
  'teal',
  'indigo',
  'violet',
  'gold',
  'silver',
  'bronze',
  'maroon',
  'navy',
  'olive',
  'lime',
  'coral',
  'turquoise',
  'peach',
  'salmon',
  'lavender',
  'charcoal',
  'amber',
  'mint green',
  'emerald',
  'sapphire',
  'ruby red',
  'rose gold',
  'periwinkle',
  'tan',
  'aquamarine',
  'chartreuse',
  'crimson',
  'fuchsia',
  'ivory',
  'khaki',
  'mustard',
  'plum',
  'scarlet',
  'sepia',
  'slate gray',
  'taupe',
];
