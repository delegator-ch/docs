// lib/services/base_service.dart

import 'dart:async';

/// Base interface for all API services
/// T represents the model type
abstract class BaseService<T> {
  /// Fetch a list of all entities
  Future<List<T>> getAll();

  /// Fetch a single entity by ID
  Future<T> getById(int id);

  /// Create a new entity
  Future<T> create(T item);

  /// Update an existing entity
  Future<T> update(T item);

  /// Delete an entity by ID
  Future<bool> delete(int id);
}
