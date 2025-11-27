enum UserRole { client, worker, admin }

enum OrderStatus {
  pending,      // 0 - Coincide con backend
  accepted,     // 1 - Coincide con backend
  inProgress,   // 2 - NUEVO: InProgress en backend
  delivered,    // 3 - NUEVO: Delivered en backend
  completed,    // 4 - CORREGIDO: Completed es 4 en backend
  cancelled,    // 5 - Coincide con backend
}
