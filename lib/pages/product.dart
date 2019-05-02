import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';

import '../widgets/ui_elements/title_default.dart';
import '../scoped-models/main.dart';
import '../models/product.dart';

class ProductPage extends StatelessWidget {
  final Product product;

  ProductPage(this.product);

  Widget _buildProductRow(double price) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          'Union Square, San Francisco',
          style: TextStyle(
              fontFamily: 'Oswald', fontSize: 15.0, color: Colors.grey),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            '|',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        Text(
          '\$' + price.toString(),
          style: TextStyle(
              fontFamily: 'Oswald', fontSize: 15.0, color: Colors.grey),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () {
          print('product detail page pop up');
          Navigator.pop(context, false);
          return Future.value(false);
        },
        child:
            // ScopedModelDescendant<MainModel>(
            //   builder: (BuildContext context, Widget child, MainModel model) {
            //     final Product product = model.selectedProduct; //allProducts[productIndex];
            //     return
            Scaffold(
          appBar: AppBar(
            title: Text(product.title),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Image.network(product.image),
              Container(
                child: TitleDefault(product.title),
                padding: EdgeInsets.all(10.0),
              ),
              _buildProductRow(product.price),
              Container(
                padding: EdgeInsets.all(10.0),
                child: Text(
                  product.description,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        )
        //   },
        // ),
        );
  }
}
