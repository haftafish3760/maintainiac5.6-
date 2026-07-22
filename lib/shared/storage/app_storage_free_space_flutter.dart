import 'package:disk_space_plus/disk_space_plus.dart';

Future<double?> readAppFreeDiskSpaceMb() => DiskSpacePlus().getFreeDiskSpace;
