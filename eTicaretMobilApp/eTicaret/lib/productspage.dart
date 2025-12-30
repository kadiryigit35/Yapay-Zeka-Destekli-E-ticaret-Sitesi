import 'package:flutter/material.dart';
import 'main.dart';
import 'models.dart';

class ProductsPage extends StatefulWidget {
  final String? initialSearchQuery;

  const ProductsPage({Key? key, this.initialSearchQuery}) : super(key: key);

  @override
  _ProductsPageState createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List<Product> products = [];
  List<Category> categories = [];
  List<Satici> saticilar = [];
  bool isLoading = true;
  String? errorMessage;

  List<int> selectedCategoryIds = [];
  List<int> selectedSellerIds = [];
  TextEditingController minPriceController = TextEditingController();
  TextEditingController maxPriceController = TextEditingController();
  TextEditingController searchController = TextEditingController();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Eğer widget'a bir başlangıç sorgusu iletilmişse,
    // searchController'ın metnini bu sorguyla başlat.
    if (widget.initialSearchQuery != null &&
        widget.initialSearchQuery!.isNotEmpty) {
      searchController.text = widget.initialSearchQuery!;
    }
    _loadInitialData(); // Bu fonksiyon zaten _applyFilters'ı çağırıyor.
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    try {
      final loadedCategories = await ApiService.getCategories();
      final loadedSellers = await ApiService.getSellers();
      if (mounted) {
        setState(() {
          categories = loadedCategories;
          saticilar = loadedSellers;
        });
      }
      // aPI'den verileri çektikten sonra filtreleri uygula
      await _applyFilters();
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Veriler yüklenirken hata oluştu: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _applyFilters() async {
    if (mounted) setState(() => isLoading = true);
    try {
      final loadedProducts = await ApiService.getFilteredProducts(
        kategoriIds: selectedCategoryIds,
        saticiIds: selectedSellerIds,
        minFiyat: double.tryParse(minPriceController.text),
        maxFiyat: double.tryParse(maxPriceController.text),
        searchQuery: searchController.text.trim(),
      );
      if (mounted) {
        setState(() {
          products = loadedProducts;
          isLoading = false;
          errorMessage = null; // Başarılı olursa eski hatayı temizle
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Ürünler yüklenirken hata oluştu: $e';
          isLoading = false;
        });
      }
    }
  }

  void _clearFilters() {
    setState(() {
      selectedCategoryIds.clear();
      selectedSellerIds.clear();
      minPriceController.clear();
      maxPriceController.clear();
      // Arama çubuğunu temizleme opsiyoneldir, istenirse eklenebilir.
      // searchController.clear();
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Ürün ara...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
            suffixIcon: searchController.text.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.clear, color: Colors.white),
              onPressed: () {
                searchController.clear();
                _applyFilters();
                FocusScope.of(context).unfocus(); // Klavyeyi gizle
              },
            )
                : Icon(Icons.search, color: Colors.white),
          ),
          style: TextStyle(color: Colors.white),
          onSubmitted: (_) => _applyFilters(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            tooltip: 'Filtrele',
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      endDrawer: _buildFilterDrawer(),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
          child: Padding(
              padding: const EdgeInsets.all(16.0),
              child:
              Text(errorMessage!, textAlign: TextAlign.center)))
          : products.isEmpty
          ? Center(child: Text('Bu kriterlere uygun ürün bulunamadı.'))
          : RefreshIndicator(
        onRefresh: _loadInitialData,
        child: GridView.builder(
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65, // Kartların oranını ayarla
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            // main.dart içerisindeki ProductCard widget'ı kullanılıyor
            return ProductCard(product: products[index]);
          },
        ),
      ),
    );
  }

  Widget _buildFilterDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  _buildSectionTitle('Kategoriler'),
                  ...categories.map((c) => CheckboxListTile(
                    title: Text(c.adi),
                    value: selectedCategoryIds.contains(c.id),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          selectedCategoryIds.add(c.id);
                        } else {
                          selectedCategoryIds.remove(c.id);
                        }
                      });
                    },
                  )),
                  Divider(),
                  _buildSectionTitle('Markalar'),
                  ...saticilar.map((s) => CheckboxListTile(
                    title: Text(s.adi),
                    value: selectedSellerIds.contains(s.id),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          selectedSellerIds.add(s.id);
                        } else {
                          selectedSellerIds.remove(s.id);
                        }
                      });
                    },
                  )),
                  Divider(),
                  _buildSectionTitle('Fiyat Aralığı'),
                  SizedBox(height: 8),
                  TextField(
                      controller: minPriceController,
                      keyboardType:
                      TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                          labelText: 'Min Fiyat', border: OutlineInputBorder())),
                  SizedBox(height: 12),
                  TextField(
                      controller: maxPriceController,
                      keyboardType:
                      TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                          labelText: 'Max Fiyat', border: OutlineInputBorder())),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _clearFilters();
                        Navigator.of(context).pop();
                      },
                      child: Text('Temizle'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _applyFilters();
                        Navigator.of(context).pop();
                      },
                      child: Text('Uygula'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}