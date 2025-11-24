enum UserRole { client, worker, admin }

enum OrderStatus {
  pending,   // 0
  accepted,  // 1
  rejected,  // 2
  completed, // 3
  cancelled, // 4
  refunded,  // 5  ← NUEVO, COINCIDE CON EL BACKEND
}
