import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

DateFormat yMMMd(BuildContext context) =>
    DateFormat.yMMMd(localeOf(context));

DateFormat yMMM(BuildContext context) =>
    DateFormat.yMMM(localeOf(context));

DateFormat yMMMM(BuildContext context) =>
    DateFormat.yMMMM(localeOf(context));

DateFormat yMMMMEEEEd(BuildContext context) =>
    DateFormat.yMMMMEEEEd(localeOf(context));

DateFormat MMMd(BuildContext context) =>
    DateFormat.MMMd(localeOf(context));

DateFormat MMM(BuildContext context) =>
    DateFormat.MMM(localeOf(context));

DateFormat MMMEd(BuildContext context) =>
    DateFormat.MMMEd(localeOf(context));

DateFormat jm(BuildContext context) =>
    DateFormat.jm(localeOf(context));

DateFormat Hm(BuildContext context) =>
    DateFormat.Hm(localeOf(context));

String localeOf(BuildContext context) =>
    Localizations.localeOf(context).toLanguageTag();
