import 'package:flutter/material.dart';

import './widgets/products/products.dart';
import './product_control.dart';
import './models/product.dart';

class ProductManager extends StatelessWidget {

  final List<Product> products;

  ProductManager(this.products);

  
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Column(
      children: <Widget>[
        Expanded(
          child: Products(),
        )
      ],
    );
  }
}
