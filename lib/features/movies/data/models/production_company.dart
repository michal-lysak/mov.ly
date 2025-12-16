import 'package:hive/hive.dart';
part 'production_company.g.dart';

@HiveType(typeId: 1)
class ProductionCompany {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  ProductionCompany({required this.id, required this.name});
}
