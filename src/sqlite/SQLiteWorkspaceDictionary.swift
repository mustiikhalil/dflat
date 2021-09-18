import Dflat
import Dispatch
import FlatBuffers
import Foundation

struct SQLiteWorkspaceDictionary: WorkspaceDictionary {
  enum None {
    case none
  }
  final class Storage {
    static let size = 8
    var locks: UnsafeMutablePointer<os_unfair_lock_s>
    var dictionaries: [[String: Any]]
    init() {
      locks = UnsafeMutablePointer.allocate(capacity: Self.size)
      locks.assign(repeating: os_unfair_lock(), count: Self.size)
      dictionaries = Array(repeating: [String: Any](), count: Self.size)
    }
    deinit {
      locks.deallocate()
    }
  }
  let workspace: SQLiteWorkspace
  let storage: Storage
  subscript<T: Codable>(key: String) -> T? {
    get {
      let tuple = storage.getAndLock(key)
      if let value = tuple.0 {
        storage.unlock(tuple.1)
        return value is None ? nil : (value as! T)
      }  // Otherwise, try to load from disk.
      storage.unlock(tuple.1)
      if let value = workspace.fetch(for: DictItem.self).where(DictItem.key == key).first {
        assert(value.valueType == .codableValue)
        let object: T? = value.codable.withUnsafeBytes {
          guard let baseAddress = $0.baseAddress else { return nil }
          let decoder = PropertyListDecoder()
          var format = PropertyListSerialization.PropertyListFormat.binary
          return try? decoder.decode(
            T.self,
            from: Data(
              bytesNoCopy: UnsafeMutableRawPointer(mutating: baseAddress), count: $0.count,
              deallocator: .none), format: &format)
        }
        storage.lock(tuple.1)
        // If no one else populated the cache, do that now.
        if storage.get(key, hashValue: tuple.1) == nil {
          storage.set(key, hashValue: tuple.1, value: object ?? SQLiteWorkspaceDictionary.None.none)
        }
        storage.unlock(tuple.1)
        return object
      } else {
        storage.lock(tuple.1)
        // If no one else populated the cache, do that now.
        if storage.get(key, hashValue: tuple.1) == nil {
          storage.set(key, hashValue: tuple.1, value: SQLiteWorkspaceDictionary.None.none)
        }
        storage.unlock(tuple.1)
      }
      return nil
    }
    set {
      let hashValue = storage.setAndLock(
        key, value: newValue ?? SQLiteWorkspaceDictionary.None.none)
      if let value = newValue {
        // Encode on current thread. Codable can be customized, hence, there is no guarantee it is thread-safe.
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        do {
          let data = try encoder.encode(value)
          storage.upsert(
            workspace, item: DictItem(key: key, valueType: .codableValue, codable: Array(data)))
        } catch {
          // TODO: Log the error.
        }
      } else {
        storage.remove(workspace, key: key)
      }
      storage.unlock(hashValue)
    }
  }
  subscript<T: FlatBuffersCodable>(key: String) -> T? {
    get {
      let tuple = storage.getAndLock(key)
      if let value = tuple.0 {
        storage.unlock(tuple.1)
        return value is None ? nil : (value as! T)
      }  // Otherwise, try to load from disk.
      storage.unlock(tuple.1)
      if let value = workspace.fetch(for: DictItem.self).where(DictItem.key == key).first {
        assert(value.valueType == .flatBuffersValue)
        let object: T? = value.codable.withUnsafeBytes {
          guard let baseAddress = $0.baseAddress else { return nil }
          return T.from(
            byteBuffer: ByteBuffer(
              assumingMemoryBound: UnsafeMutableRawPointer(mutating: baseAddress),
              capacity: $0.count))
        }
        storage.lock(tuple.1)
        // If no one else populated the cache, do that now.
        if storage.get(key, hashValue: tuple.1) == nil {
          storage.set(key, hashValue: tuple.1, value: object ?? SQLiteWorkspaceDictionary.None.none)
        }
        storage.unlock(tuple.1)
        return object
      } else {
        storage.lock(tuple.1)
        // If no one else populated the cache, do that now.
        if storage.get(key, hashValue: tuple.1) == nil {
          storage.set(key, hashValue: tuple.1, value: SQLiteWorkspaceDictionary.None.none)
        }
        storage.unlock(tuple.1)
        return nil
      }
    }
    set {
      let hashValue = storage.setAndLock(
        key, value: newValue ?? SQLiteWorkspaceDictionary.None.none)
      if let value = newValue {
        storage.upsert(workspace) {
          var fbb = FlatBufferBuilder()
          let offset = value.to(flatBufferBuilder: &fbb)
          fbb.finish(offset: offset)
          return DictItem(key: key, valueType: .flatBuffersValue, codable: fbb.sizedByteArray)
        }
      } else {
        storage.remove(workspace, key: key)
      }
      storage.unlock(hashValue)
    }
  }
  subscript(key: String) -> Bool? {
    get {
      let tuple = storage.getAndLock(key)
      if let value = tuple.0 {
        storage.unlock(tuple.1)
        return value is None ? nil : (value as! Bool)
      }  // Otherwise, try to load from disk.
      storage.unlock(tuple.1)
      if let value = workspace.fetch(for: DictItem.self).where(DictItem.key == key).first {
        assert(value.valueType == .boolValue)
        let object = value.boolValue
        storage.lock(tuple.1)
        // If no one else populated the cache, do that now.
        if storage.get(key, hashValue: tuple.1) == nil {
          storage.set(key, hashValue: tuple.1, value: object)
        }
        storage.unlock(tuple.1)
        return object
      } else {
        storage.lock(tuple.1)
        // If no one else populated the cache, do that now.
        if storage.get(key, hashValue: tuple.1) == nil {
          storage.set(key, hashValue: tuple.1, value: SQLiteWorkspaceDictionary.None.none)
        }
        storage.unlock(tuple.1)
        return nil
      }
    }
    set {
      let hashValue = storage.setAndLock(
        key, value: newValue ?? SQLiteWorkspaceDictionary.None.none)
      if let value = newValue {
        storage.upsert(workspace, item: DictItem(key: key, valueType: .boolValue, boolValue: value))
      } else {
        storage.remove(workspace, key: key)
      }
      storage.unlock(hashValue)
    }
  }
  subscript(key: String) -> Int? {
    get {
      let tuple = storage.getAndLock(key)
      if let value = tuple.0 {
        storage.unlock(tuple.1)
        return value is None ? nil : (value as! Int)
      }  // Otherwise, try to load from disk.
      storage.unlock(tuple.1)
      if let value = workspace.fetch(for: DictItem.self).where(DictItem.key == key).first {
        assert(value.valueType == .longValue)
        let object = Int(value.longValue)
        storage.lock(tuple.1)
        // If no one else populated the cache, do that now.
        if storage.get(key, hashValue: tuple.1) == nil {
          storage.set(key, hashValue: tuple.1, value: object)
        }
        storage.unlock(tuple.1)
        return object
      } else {
        storage.lock(tuple.1)
        // If no one else populated the cache, do that now.
        if storage.get(key, hashValue: tuple.1) == nil {
          storage.set(key, hashValue: tuple.1, value: SQLiteWorkspaceDictionary.None.none)
        }
        storage.unlock(tuple.1)
        return nil
      }
    }
    set {
      let hashValue = storage.setAndLock(
        key, value: newValue ?? SQLiteWorkspaceDictionary.None.none)
      if let value = newValue {
        storage.upsert(
          workspace, item: DictItem(key: key, valueType: .longValue, longValue: Int64(value)))
      } else {
        storage.remove(workspace, key: key)
      }
      storage.unlock(hashValue)
    }
  }
  subscript(key: String) -> UInt? {
    get {
      let tuple = storage.getAndLock(key)
      if let value = tuple.0 {
        storage.unlock(tuple.1)
        return value is None ? nil : (value as! UInt)
      }  // Otherwise, try to load from disk.
      storage.unlock(tuple.1)
      if let value = workspace.fetch(for: DictItem.self).where(DictItem.key == key).first {
        assert(value.valueType == .unsignedLongValue)
        let object = UInt(value.unsignedLongValue)
        storage.lock(tuple.1)
        // If no one else populated the cache, do that now.
        if storage.get(key, hashValue: tuple.1) == nil {
          storage.set(key, hashValue: tuple.1, value: object)
        }
        storage.unlock(tuple.1)
        return object
      } else {
        storage.lock(tuple.1)
        // If no one else populated the cache, do that now.
        if storage.get(key, hashValue: tuple.1) == nil {
          storage.set(key, hashValue: tuple.1, value: SQLiteWorkspaceDictionary.None.none)
        }
        storage.unlock(tuple.1)
        return nil
      }
    }
    set {
      let hashValue = storage.setAndLock(
        key, value: newValue ?? SQLiteWorkspaceDictionary.None.none)
      if let value = newValue {
        storage.upsert(
          workspace,
          item: DictItem(key: key, valueType: .unsignedLongValue, unsignedLongValue: UInt64(value)))
      } else {
        storage.remove(workspace, key: key)
      }
      storage.unlock(hashValue)
    }
  }
  subscript(key: String) -> Float? {
    get {
      let tuple = storage.getAndLock(key)
      if let value = tuple.0 {
        storage.unlock(tuple.1)
        return value is None ? nil : (value as! Float)
      }  // Otherwise, try to load from disk.
      storage.unlock(tuple.1)
      if let value = workspace.fetch(for: DictItem.self).where(DictItem.key == key).first {
        assert(value.valueType == .floatValue)
        let object = value.floatValue
        storage.lock(tuple.1)
        // If no one else populated the cache, do that now.
        if storage.get(key, hashValue: tuple.1) == nil {
          storage.set(key, hashValue: tuple.1, value: object)
        }
        storage.unlock(tuple.1)
        return object
      } else {
        storage.lock(tuple.1)
        // If no one else populated the cache, do that now.
        if storage.get(key, hashValue: tuple.1) == nil {
          storage.set(key, hashValue: tuple.1, value: SQLiteWorkspaceDictionary.None.none)
        }
        storage.unlock(tuple.1)
        return nil
      }
    }
    set {
      let hashValue = storage.setAndLock(
        key, value: newValue ?? SQLiteWorkspaceDictionary.None.none)
      if let value = newValue {
        storage.upsert(
          workspace, item: DictItem(key: key, valueType: .floatValue, floatValue: value))
      } else {
        storage.remove(workspace, key: key)
      }
      storage.unlock(hashValue)
    }
  }
  subscript(key: String) -> Double? {
    get {
      let tuple = storage.getAndLock(key)
      if let value = tuple.0 {
        storage.unlock(tuple.1)
        return value is None ? nil : (value as! Double)
      }  // Otherwise, try to load from disk.
      storage.unlock(tuple.1)
      if let value = workspace.fetch(for: DictItem.self).where(DictItem.key == key).first {
        assert(value.valueType == .doubleValue)
        let object = value.doubleValue
        storage.lock(tuple.1)
        // If no one else populated the cache, do that now.
        if storage.get(key, hashValue: tuple.1) == nil {
          storage.set(key, hashValue: tuple.1, value: object)
        }
        storage.unlock(tuple.1)
        return object
      } else {
        storage.lock(tuple.1)
        // If no one else populated the cache, do that now.
        if storage.get(key, hashValue: tuple.1) == nil {
          storage.set(key, hashValue: tuple.1, value: SQLiteWorkspaceDictionary.None.none)
        }
        storage.unlock(tuple.1)
        return nil
      }
    }
    set {
      let hashValue = storage.setAndLock(
        key, value: newValue ?? SQLiteWorkspaceDictionary.None.none)
      if let value = newValue {
        storage.upsert(
          workspace, item: DictItem(key: key, valueType: .doubleValue, doubleValue: value))
      } else {
        storage.remove(workspace, key: key)
      }
      storage.unlock(hashValue)
    }
  }
  subscript(key: String) -> String? {
    get {
      let tuple = storage.getAndLock(key)
      if let value = tuple.0 {
        storage.unlock(tuple.1)
        return value is None ? nil : (value as! String)
      }  // Otherwise, try to load from disk.
      storage.unlock(tuple.1)
      if let value = workspace.fetch(for: DictItem.self).where(DictItem.key == key).first {
        assert(value.valueType == .stringValue)
        let object = value.stringValue
        storage.lock(tuple.1)
        // If no one else populated the cache, do that now.
        if storage.get(key, hashValue: tuple.1) == nil {
          storage.set(key, hashValue: tuple.1, value: object ?? SQLiteWorkspaceDictionary.None.none)
        }
        storage.unlock(tuple.1)
        return object
      } else {
        storage.lock(tuple.1)
        // If no one else populated the cache, do that now.
        if storage.get(key, hashValue: tuple.1) == nil {
          storage.set(key, hashValue: tuple.1, value: SQLiteWorkspaceDictionary.None.none)
        }
        storage.unlock(tuple.1)
        return nil
      }
    }
    set {
      let hashValue = storage.setAndLock(
        key, value: newValue ?? SQLiteWorkspaceDictionary.None.none)
      if let value = newValue {
        storage.upsert(
          workspace, item: DictItem(key: key, valueType: .stringValue, stringValue: value))
      } else {
        storage.remove(workspace, key: key)
      }
      storage.unlock(hashValue)
    }
  }
  func synchronize() {
    let group = DispatchGroup()
    group.enter()
    workspace.performChanges(
      [DictItem.self], changesHandler: { _ in },
      completionHandler: { _ in
        group.leave()
      })
    group.wait()
  }
}

extension SQLiteWorkspaceDictionary.Storage {
  @inline(__always)
  func getAndLock(_ key: String) -> (Any?, Int) {
    var hasher = Hasher()
    key.hash(into: &hasher)
    let hashValue = Int(UInt(bitPattern: hasher.finalize()) % UInt(Self.size))
    os_unfair_lock_lock(locks + hashValue)
    return (dictionaries[hashValue][key], hashValue)
  }
  @inline(__always)
  func setAndLock(_ key: String, value: Any) -> Int {
    var hasher = Hasher()
    key.hash(into: &hasher)
    let hashValue = Int(UInt(bitPattern: hasher.finalize()) % UInt(Self.size))
    os_unfair_lock_lock(locks + hashValue)
    dictionaries[hashValue][key] = value
    return hashValue
  }
  @inline(__always)
  func get(_ key: String, hashValue: Int) -> Any? {
    return dictionaries[hashValue][key]
  }
  @inline(__always)
  func set(_ key: String, hashValue: Int, value: Any) {
    dictionaries[hashValue][key] = value
  }
  @inline(__always)
  func upsert(_ workspace: SQLiteWorkspace, item: @escaping () -> DictItem) {
    workspace.performChanges([DictItem.self]) {
      let upsertRequest = DictItemChangeRequest.upsertRequest(item())
      $0.try(submit: upsertRequest)
    }
  }
  @inline(__always)
  func upsert(_ workspace: SQLiteWorkspace, item: DictItem) {
    workspace.performChanges([DictItem.self]) {
      let upsertRequest = DictItemChangeRequest.upsertRequest(item)
      $0.try(submit: upsertRequest)
    }
  }
  @inline(__always)
  func remove(_ workspace: SQLiteWorkspace, key: String) {
    workspace.performChanges([DictItem.self]) {
      if let deletionRequest = DictItemChangeRequest.deletionRequest(DictItem(key: key)) {
        $0.try(submit: deletionRequest)
      }
    }
  }
  @inline(__always)
  func lock(_ hashValue: Int) {
    os_unfair_lock_lock(locks + hashValue)
  }
  @inline(__always)
  func unlock(_ hashValue: Int) {
    os_unfair_lock_unlock(locks + hashValue)
  }
}
