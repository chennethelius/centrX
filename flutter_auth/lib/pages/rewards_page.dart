import 'package:flutter/material.dart';
import 'dart:ui';

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> favorites = ['prof-smith', 'prof-garcia'];
  List<Professor> cart = [];
  int studentPoints = 100;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Professor> get professors => [
    Professor(
      id: 'prof-smith',
      name: 'Dr. Sarah Smith',
      subject: 'Mathematics',
      points: 150,
      rating: 4.9,
      description: '2 bonus points on next exam',
      emoji: '🧮',
      featured: true,
      popular: true,
      gradientColors: [Color(0xFF6B73FF), Color(0xFF000DFF)],
    ),
    Professor(
      id: 'prof-johnson',
      name: 'Prof. Mike Johnson',
      subject: 'Physics',
      points: 200,
      rating: 4.8,
      description: 'Extra credit assignment worth 5%',
      emoji: '🔬',
      featured: true,
      gradientColors: [Color(0xFF9796F0), Color(0xFFFBC7D4)],
    ),
    Professor(
      id: 'prof-garcia',
      name: 'Dr. Maria Garcia',
      subject: 'Chemistry',
      points: 175,
      rating: 4.7,
      description: 'Lab report extension + 3 bonus points',
      emoji: '⚗️',
      featured: false,
      gradientColors: [Color(0xFFA8EDEA), Color(0xFFFED6E3)],
    ),
    Professor(
      id: 'prof-chen',
      name: 'Prof. David Chen',
      subject: 'Computer Science',
      points: 250,
      rating: 4.9,
      description: 'Skip one coding assignment',
      emoji: '💻',
      featured: true,
      popular: true,
      gradientColors: [Color(0xFF667eea), Color(0xFF764ba2)],
    ),
    Professor(
      id: 'prof-williams',
      name: 'Dr. Emily Williams',
      subject: 'Biology',
      points: 125,
      rating: 4.6,
      description: '1 bonus point + study guide',
      emoji: '🧬',
      featured: false,
      gradientColors: [Color(0xFFf093fb), Color(0xFFf5576c)],
    ),
    Professor(
      id: 'prof-brown',
      name: 'Prof. Robert Brown',
      subject: 'History',
      points: 100,
      rating: 4.5,
      description: 'Essay deadline extension',
      emoji: '📚',
      featured: false,
      gradientColors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
    ),
  ];

  List<Professor> getFilteredProfessors() {
    switch (_tabController.index) {
      case 0: // Featured
        return professors.where((prof) => prof.featured).toList();
      case 1: // Menu
        return professors;
      case 2: // Favorites
        return professors.where((prof) => favorites.contains(prof.id)).toList();
      default:
        return professors;
    }
  }

  void toggleFavorite(String profId) {
    setState(() {
      if (favorites.contains(profId)) {
        favorites.remove(profId);
      } else {
        favorites.add(profId);
      }
    });
  }

  void addToCart(Professor professor) {
    if (studentPoints >= professor.points) {
      setState(() {
        cart.add(professor);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${professor.name} added to cart!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 126, 203, 255),
              Color(0xFF6366F1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Points Card
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.25),
                            Colors.white.withValues(alpha: 0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Available Points',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    '$studentPoints pts',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 30,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Tab Bar
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.8),
                                  Colors.white.withValues(alpha: 0.6),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelColor: Color(0xFF1e3c72),
                            unselectedLabelColor: Colors.white.withValues(alpha: 0.8),
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            onTap: (index) => setState(() {}),
                            tabs: [
                              Tab(text: 'Featured'),
                              Tab(text: 'Favorites'),
                              Tab(text: 'Menu'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content Section
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Featured Tab
                      _buildProfessorGrid(getFilteredProfessors()),
                      // Favorites Tab
                      _buildProfessorGrid(getFilteredProfessors()),
                      // Menu Tab
                      _buildProfessorGrid(getFilteredProfessors()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: cart.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showCartDialog(),
              backgroundColor: Colors.green,
              icon: Icon(Icons.shopping_cart),
              label: Text('Cart (${cart.length})'),
            )
          : null,
    );
  }

  Widget _buildProfessorGrid(List<Professor> professors) {
    if (professors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 60,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            SizedBox(height: 20),
            Text(
              'No professors found',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 18,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.only(bottom: 100),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        childAspectRatio: 1.7,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: professors.length,
      itemBuilder: (context, index) {
        return _buildProfessorCard(professors[index]);
      },
    );
  }

  Widget _buildProfessorCard(Professor professor) {
    bool isFavorite = favorites.contains(professor.id);
    bool canAfford = studentPoints >= professor.points;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.25),
            Colors.white.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Stack(
            children: [
              // Popular badge
              if (professor.popular)
                Positioned(
                  top: 15,
                  right: 15,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.25)],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.trending_up, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Popular',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Favorite button
              Positioned(
                top: 15,
                left: 15,
                child: GestureDetector(
                  onTap: () => toggleFavorite(professor.id),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              // Main content
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 30),
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: professor.gradientColors,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Center(
                            child: Text(
                              professor.emoji,
                              style: TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                professor.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                professor.subject,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(Icons.star, color: Colors.amber, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    professor.rating.toString(),
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Text(
                      professor.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                    Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.stars, color: Colors.amber, size: 16),
                            SizedBox(width: 5),
                            Text(
                              '${professor.points} pts',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: canAfford ? () => addToCart(professor) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canAfford ? const Color.fromARGB(255, 139, 232, 142) : Colors.grey,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 16, color: Colors.white),
                              SizedBox(width: 5),
                              Text(canAfford ? 'Redeem' : 'Not enough'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cart Items'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: cart.map((prof) => ListTile(
            leading: Text(prof.emoji),
            title: Text(prof.name),
            subtitle: Text('${prof.points} pts'),
            trailing: IconButton(
              icon: Icon(Icons.remove),
              onPressed: () {
                setState(() {
                  cart.remove(prof);
                });
                Navigator.pop(context);
              },
            ),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // Process order
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Order placed successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
              setState(() {
                cart.clear();
              });
            },
            child: Text('Order'),
          ),
        ],
      ),
    );
  }
}

class Professor {
  final String id;
  final String name;
  final String subject;
  final int points;
  final double rating;
  final String description;
  final String emoji;
  final bool featured;
  final bool popular;
  final List<Color> gradientColors;

  Professor({
    required this.id,
    required this.name,
    required this.subject,
    required this.points,
    required this.rating,
    required this.description,
    required this.emoji,
    this.featured = false,
    this.popular = false,
    required this.gradientColors,
  });
}
