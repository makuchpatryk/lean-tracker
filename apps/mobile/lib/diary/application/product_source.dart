import '../domain/product_snapshot.dart';

/// Where the products to log come from. In M3 a debug-only seed list; M4 replaces it with the products
/// module (search, favorites, recents).
abstract interface class ProductSource {
  List<ProductSnapshot> products();
}
