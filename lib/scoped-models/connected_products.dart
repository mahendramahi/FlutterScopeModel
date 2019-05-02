import 'dart:convert';
import 'dart:async';

import 'package:scoped_model/scoped_model.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/subjects.dart';

import '../models/product.dart';
import '../models/user.dart';
import '../models/auth.dart';

mixin ConnectedProductsModel on Model {
  List<Product> _products = [];
  String _selProductId;
  User _authenticatedUser;
  bool _isLoading = false;
}

mixin ProductsModel on ConnectedProductsModel {
  bool _showFavorites = false;

  List<Product> get allProducts {
    return List.from(_products);
  }

  List<Product> get displayedProducts {
    if (_showFavorites) {
      return _products.where((Product product) => product.isFavorite).toList();
    }
    return List.from(_products);
  }

  int get localselectedProductIndex {
    return _products.indexWhere((Product product) {
      return product.id == _selProductId;
    });
  }

  String get selectedProductId {
    return _selProductId;
  }

  Product get selectedProduct {
    if (selectedProductId == null) {
      return null;
    }
    return _products.firstWhere((Product product) {
      return product.id == _selProductId;
    });
  }

  bool get displayFavoritesStatus {
    return _showFavorites;
  }

  Future<bool> addProduct(
      String title, String description, String image, double price) async {
    _isLoading = true;
    notifyListeners();
    final Map<String, dynamic> productData = {
      'title': title,
      'description': description,
      'image': 'https://homepages.cae.wisc.edu/~ece533/images/girl.png',
      'price': price,
      'userEmail': _authenticatedUser.email,
      'userId': _authenticatedUser.id
    };

    try {
      final http.Response response = await http.post(
          'https://flutter-products-5c991.firebaseio.com/products.json?auth=${_authenticatedUser.token}',
          body: json.encode(productData));

      if (response.statusCode != 200 && response.statusCode != 201) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _isLoading = false;
      final Map<String, dynamic> responseData = json.decode(response.body);
      print(responseData);
      final Product newProduct = Product(
          id: responseData['name'],
          title: title,
          description: description,
          image: image,
          price: price,
          userEmail: _authenticatedUser.email,
          userId: _authenticatedUser.id);
      _products.add(newProduct);
      notifyListeners();
      return true;
    } catch (error) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(
      String title, String description, String image, double price) {
    _isLoading = true;
    notifyListeners();

    final Map<String, dynamic> updateData = {
      'title': title,
      'description': description,
      'image': 'https://homepages.cae.wisc.edu/~ece533/images/pool.png',
      'price': price,
      'userEmail': selectedProduct.userEmail,
      'userId': selectedProduct.id
    };

    return http
        .put(
            'https://flutter-products-5c991.firebaseio.com/products/${selectedProduct.id}.json?auth=${_authenticatedUser.token}',
            body: json.encode(updateData))
        .then((http.Response response) {
      if (response.statusCode != 200 && response.statusCode != 201) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _isLoading = false;
      final Product updatedProduct = Product(
          id: selectedProduct.id,
          title: title,
          description: description,
          image: image,
          price: price,
          userEmail: _authenticatedUser.email,
          userId: _authenticatedUser.id);
      _products[localselectedProductIndex] = updatedProduct;
      notifyListeners();
      return true;
    }).catchError((error) {
      _isLoading = false;
      notifyListeners();
      return false;
    });
  }

  Future<Null> fetchProducts() {
    _isLoading = true;
    notifyListeners();
    return http
        .get(
            'https://flutter-products-5c991.firebaseio.com/products.json?auth=${_authenticatedUser.token}')
        .then<Null>((http.Response response) {
      if (response.statusCode != 200 && response.statusCode != 201) {
        _isLoading = true;
        notifyListeners();
        return;
      }

      print(json.decode(response.body));

      final List<Product> fetchedProductList = [];

      final Map<String, dynamic> productListData = json.decode(response.body);
      if (productListData == null) {
        print('null data');
        _isLoading = false;
        notifyListeners();
        print(_isLoading);
        return;
      }
      print('not null data');
      productListData.forEach((String productId, dynamic productData) {
        final Product newProduct = new Product(
          id: productId,
          title: productData['title'],
          description: productData['description'],
          image: productData['image'],
          price: productData['price'],
          userEmail: productData['userEmail'],
          userId: productData['userId'],
        );
        fetchedProductList.add(newProduct);
      });
      _products = fetchedProductList;
      _isLoading = false;
      notifyListeners();
      // _selProductId = null;
    }).catchError((error) {
      _isLoading = false;
      notifyListeners();
      return;
    });
  }

  Future<bool> deleteProduct() {
    _isLoading = true;
    final String deletedProductId = selectedProduct.id;
    _products.removeAt(localselectedProductIndex);
    _selProductId = null;
    notifyListeners();
    return http
        .delete(
            'https://flutter-products-5c991.firebaseio.com/products/${deletedProductId}.json?auth=${_authenticatedUser.token}')
        .then((http.Response response) {
      if (response.statusCode != 200 && response.statusCode != 201) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    }).catchError((error) {
      _isLoading = false;
      notifyListeners();
      return false;
    });
  }

  void toggleProductFavoriteStatus() {
    final bool isCurrentlyFavorite = selectedProduct.isFavorite;
    final bool newFavoritesStatus = !isCurrentlyFavorite;
    final Product updatedProduct = Product(
        title: selectedProduct.title,
        description: selectedProduct.description,
        price: selectedProduct.price,
        image: selectedProduct.image,
        userEmail: selectedProduct.userEmail,
        userId: selectedProduct.userId,
        isFavorite: newFavoritesStatus);
    _products[localselectedProductIndex] = updatedProduct;
    notifyListeners();
  }

  void selectProduct(String productId) {
    _selProductId = productId;
    if (productId != null) {
      notifyListeners();
    }
  }

  void toggleDisplayMode() {
    _showFavorites = !_showFavorites;
    notifyListeners();
  }
}

mixin UserModel on ConnectedProductsModel {

  Timer _authTimer;

  PublishSubject<bool> _userSubject = PublishSubject();

  User get user {
    return _authenticatedUser;
  }

  PublishSubject<bool> get userSubject {
    return _userSubject;
  }

//////////
  /// @Mahendra
  ///Authanticate Function
/////////
  Future<Map<String, dynamic>> authenticate(String email, String password,
      [AuthMode mode = AuthMode.Login]) async {
    _isLoading = true;
    notifyListeners();
    //_authenticatedUser = User(id: 'gfdshjgf', email: email, password: password);

    Map<String, dynamic> loginData = {
      'email': email,
      'password': password,
      'returnSecureToken': true,
    };
    http.Response response;

    if (mode == AuthMode.Login) {
      response = await http.post(
        'https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyPassword?key=AIzaSyDk7ChP7xZwnwY3JnVhqi0TkiCdftr72OM',
        body: json.encode(loginData),
        headers: {'Content-Type': 'application/json'},
      );
    } else {
      response = await http.post(
        'https://www.googleapis.com/identitytoolkit/v3/relyingparty/signupNewUser?key=AIzaSyDk7ChP7xZwnwY3JnVhqi0TkiCdftr72OM',
        body: json.encode(loginData),
        headers: {'Content-Type': 'application/json'},
      );
    }

    print(json.decode(response.body));

    final Map<String, dynamic> responseData = json.decode(response.body);
    bool hasError = true;
    String message = 'Somthing went wrong.';
    if (responseData.containsKey('idToken')) {
      hasError = false;
      message = 'Authentication successed';
      _authenticatedUser = User(
          id: responseData['localId'],
          email: email,
          token: responseData['idToken']);

      setAuthTimeout(int.parse(responseData['expiresIn']));
      final DateTime now = DateTime.now();

      final DateTime expiryTime =
          now.add(Duration(seconds: int.parse(responseData['expiresIn'])));

      ///////// Shared Prefrence
      print('save token value is  ${responseData['idToken']}');
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('token', responseData['idToken']);
      prefs.setString('userEmail', email);
      prefs.setString('userId', responseData['localId']);
      prefs.setString(
          'expiryTime',
          expiryTime
              .toIso8601String()); // toIso8601String to convert time Stemp

    } else if (responseData['error']['message'] == 'EMAIL_NOT_FOUND') {
      hasError = true;
      message = 'This email was not found.';
    } else if (responseData['error']['message'] == 'INVALID_PASSWORD') {
      hasError = true;
      message = 'This password invalid.';
    } else if (responseData['error']['message'] == 'EMAIL_EXISTS') {
      hasError = true;
      message = 'This email already exist.';
    }
    _isLoading = false;
    notifyListeners();
    return {'success': !hasError, 'message': message};
  }

  void autoAuthenticate() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String token = prefs.getString('token');
    final String expiryTimeString = prefs.getString('expiryTime');

    print('login user token is  === ${token}');
    if (token != null) {
      final DateTime now = DateTime.now();
      final parseExpiryTime = DateTime.parse(expiryTimeString);
      if (parseExpiryTime.isBefore(now)) {
        _authenticatedUser = null;
        notifyListeners();
        return;
      }

      String userEmail = prefs.getString('userEmail');
      String userId = prefs.getString('userId');
      print('login usetr is  === ${userEmail}');

      final int tokenLifespan = parseExpiryTime.difference(now).inSeconds;
      _authenticatedUser = User(email: userEmail, id: userId, token: token);
      _userSubject.add(true);
      setAuthTimeout(tokenLifespan);
      notifyListeners();
    }
  }

  void logout() async {
    print('Logout Called');
    _authenticatedUser = null;
    _authTimer.cancel();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('token');
    prefs.remove('userEmail');
    prefs.remove('token');
    //_userSubject.add(false);
  }

  void setAuthTimeout(int time) {
    _authTimer = Timer(Duration(milliseconds: time * 5), logout);
  }

//////////
  /// @Mahendra
  ///Signup Function
/////////
  Future<Map<String, dynamic>> signup(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    Map<String, dynamic> authData = {
      'email': email,
      'password': password,
      'returnSecureToken': true,
    };

    final http.Response response = await http.post(
      'https://www.googleapis.com/identitytoolkit/v3/relyingparty/signupNewUser?key=AIzaSyDk7ChP7xZwnwY3JnVhqi0TkiCdftr72OM',
      body: json.encode(authData),
      headers: {'Content-Type': 'application/json'},
    );
    print(json.decode(response.body));

    final Map<String, dynamic> responseData = json.decode(response.body);
    bool hasError = true;
    String message = 'Somthing went wrong.';
    if (responseData.containsKey('idToken')) {
      hasError = false;
      message = 'Authentication successed';
    } else if (responseData['error']['message'] == 'EMAIL_EXISTS') {
      hasError = true;
      message = 'This email already exist.';
    }
    _isLoading = false;
    notifyListeners();
    return {'success': !hasError, 'message': message};
  }
}

mixin UtilityModel on ConnectedProductsModel {
  bool get isLoading {
    return _isLoading;
  }
}

// catchError((error) {
//   _isLoading = false;
//   notifyListeners();
//   return false;
