class CartModel {
  final String name;
  final int price;
  int qty;

  CartModel({required this.name, required this.price, this.qty = 1});

  int get total => price * qty;

  Map<String, dynamic> toMap() {
    return {'name': name, 'price': price, 'qty': qty};
  }
}
