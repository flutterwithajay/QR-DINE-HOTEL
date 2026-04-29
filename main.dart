import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }
  
  runApp(const KitchenApp());
}

class KitchenApp extends StatelessWidget {
  const KitchenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kitchen Orders',
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      home: const KitchenDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class KitchenDashboard extends StatefulWidget {
  const KitchenDashboard({super.key});

  @override
  State<KitchenDashboard> createState() => _KitchenDashboardState();
}

class _KitchenDashboardState extends State<KitchenDashboard> {
  String selectedStatus = 'pending';
  
  final List<String> tabs = ['Pending', 'Preparing', 'Ready', 'Served'];
  final List<String> statusValues = ['pending', 'preparing', 'ready', 'served'];

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order status updated to $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🍳 Kitchen Orders'),
        backgroundColor: Colors.red,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Status tabs
          Container(
            height: 50,
            margin: const EdgeInsets.all(10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                bool isSelected = selectedStatus == statusValues[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedStatus = statusValues[index];
                    });
                  },
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.red : Colors.grey[200],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(
                        tabs[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Orders list - FIXED STREAM
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .snapshots(), // REMOVED the where filter temporarily
              builder: (context, snapshot) {
                // Debug print
                print('Snapshot has data: ${snapshot.hasData}');
                print('Snapshot error: ${snapshot.error}');
                
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData) {
                  return const Center(child: Text('No data from Firestore'));
                }
                
                final allOrders = snapshot.data!.docs;
                print('Total orders in Firestore: ${allOrders.length}');
                
                // Filter orders by status
                final orders = allOrders.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['status'] == selectedStatus;
                }).toList();
                
                print('Filtered orders ($selectedStatus): ${orders.length}');
                
                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 50, color: Colors.green),
                        const SizedBox(height: 10),
                        Text('No ${tabs[statusValues.indexOf(selectedStatus)]} orders'),
                        const SizedBox(height: 10),
                        Text(
                          'Total orders in DB: ${allOrders.length}',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final doc = orders[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.table_restaurant, color: Colors.brown),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Table ${data['tableId'] ?? 'Unknown'}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(data['status'] ?? 'pending'),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    (data['status'] ?? 'pending').toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                            
                            // Items
                            ...(data['items'] as List? ?? []).map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                '${item['quantity']}x ${item['name']} - \$${item['price']}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            )),
                            
                            const Divider(),
                            
                            // Total
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total: \$${(data['total'] ?? 0).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  _formatTime(data['createdAt']),
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 15),
                            
                            // Action buttons
                            if ((data['status'] ?? '') == 'pending')
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => updateOrderStatus(doc.id, 'preparing'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('START PREPARING'),
                                ),
                              ),
                              
                            if ((data['status'] ?? '') == 'preparing')
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => updateOrderStatus(doc.id, 'ready'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('MARK READY'),
                                ),
                              ),
                              
                            if ((data['status'] ?? '') == 'ready')
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => updateOrderStatus(doc.id, 'served'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('MARK SERVED'),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'preparing': return Colors.blue;
      case 'ready': return Colors.green;
      case 'served': return Colors.grey;
      default: return Colors.grey;
    }
  }
  
  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    DateTime date = timestamp.toDate();
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}