module todolist_addr::todolist {

  #[test_only]
  friend todolist_addr::unit_tests;
  
  use aptos_framework::event;
  use std::string::String;
  use std::signer;
  use aptos_std::table::{Self, Table}; 
  use aptos_framework::account;
  use aptos_framework::account::SignerCapability;
  use aptos_framework::resource_account;
  
  struct TodoListCommon has key {
    // Storing the signer capability here, so the module can programmatically sign for transactions
    signer_cap: SignerCapability,
    tasks: Table<u64, Task>,
    set_task_event: event::EventHandle<Task>,
    task_counter: u64
  }

  struct TodoList has key {
    // Storing the signer capability here, so the module can programmatically sign for transactions
    tasks: Table<u64, Task>,
    set_task_event: event::EventHandle<Task>,
    task_counter: u64
  }
  
  struct Task has store, drop, copy {
    task_id: u64,
    address:address,
    content: String,
    completed: bool,
  }

  // Errors
  const E_NOT_INITIALIZED: u64 = 1;
  const ETASK_DOESNT_EXIST: u64 = 2;
  const ETASK_IS_COMPLETED: u64 = 3;

  fun init_module(resource_signer:&signer){
    let resource_signer_cap = resource_account::retrieve_resource_account_cap(resource_signer, @source_addr);
    let task_holder= TodoListCommon{
        signer_cap: resource_signer_cap,
        tasks: table::new(),
        set_task_event: account::new_event_handle<Task>(resource_signer),
        task_counter: 0
    };
    move_to(resource_signer,task_holder)
  }

  public entry fun create_list(account: &signer){
    let task_holder= TodoList{
        tasks: table::new(),
        set_task_event: account::new_event_handle<Task>(account),
        task_counter: 0
    };
    move_to(account,task_holder)
  }



  public entry fun create_common_task(_account: &signer, content: String) acquires TodoListCommon{
    let commonTodoList= borrow_global_mut<TodoListCommon>(@todolist_addr);
    let resource_signer = account::create_signer_with_capability(&commonTodoList.signer_cap);
    let signer_address= signer::address_of(&resource_signer);
    let counter= commonTodoList.task_counter + 1;
    let new_task= Task {
      task_id: counter,
      address: signer_address,
      content,
      completed: false
    };
    table::upsert(&mut commonTodoList.tasks,counter,new_task);
    commonTodoList.task_counter= counter;
    event::emit_event(&mut commonTodoList.set_task_event,
      new_task);
  }

   public entry fun create_task(account: &signer, content: String) acquires TodoList{
    let signer_address= signer::address_of(account);
    assert!(exists<TodoList>(signer_address), E_NOT_INITIALIZED);
    let todolist= borrow_global_mut<TodoList>(signer_address);
    let counter= todolist.task_counter + 1;
    let new_task= Task {
      task_id: counter,
      address: signer_address,
      content,
      completed: false
    };
    table::upsert(&mut todolist.tasks,counter,new_task);
    todolist.task_counter= counter;
    event::emit_event(&mut todolist.set_task_event,
      new_task);
  }

  public entry fun complete_task(account: &signer, task_id: u64) acquires TodoList{
    let signer_address= signer::address_of(account);
    assert!(exists<TodoList>(signer_address), E_NOT_INITIALIZED);
    let todolist= borrow_global_mut<TodoList>(signer_address);
    assert!(table::contains(&todolist.tasks,task_id),ETASK_DOESNT_EXIST);
    let task_record= table::borrow_mut(&mut todolist.tasks,task_id);
    assert!(task_record.completed==false,ETASK_IS_COMPLETED);
    task_record.completed= true;
  }

  public entry fun complete_common_task(_account: &signer, task_id: u64) acquires TodoListCommon{
    let commonTodoList= borrow_global_mut<TodoListCommon>(@todolist_addr);
    let resource_signer = account::create_signer_with_capability(&commonTodoList.signer_cap);
    let signer_address= signer::address_of(&resource_signer);
    assert!(exists<TodoListCommon>(signer_address), E_NOT_INITIALIZED);
    assert!(table::contains(&commonTodoList.tasks,task_id),ETASK_DOESNT_EXIST);
    let task_record= table::borrow_mut(&mut commonTodoList.tasks,task_id);
    assert!(task_record.completed==false,ETASK_IS_COMPLETED);
    task_record.completed= true;
  }

  #[test_only]
  public(friend) entry fun getEventCount(admin: &signer):u64 acquires TodoList{
    event::counter(&borrow_global<TodoList>(signer::address_of(admin)).set_task_event)
  }

  #[test_only]
  public(friend) entry fun getTaskCounter(admin: &signer):u64 acquires TodoList{
    borrow_global<TodoList>(signer::address_of(admin)).task_counter
  }

  #[test_only]
  public(friend) entry fun getTaskRecord(admin: &signer):(u64,bool,String,address) acquires TodoList{
    let todoList= borrow_global<TodoList>(signer::address_of(admin));
    let task_record=table::borrow(&todoList.tasks,todoList.task_counter);
    (task_record.task_id,task_record.completed,task_record.content,task_record.address)
  }
   #[test_only]
  public(friend) entry fun getCommonEventCount(admin: &signer):u64 acquires TodoListCommon{
    let commonTodoList= borrow_global_mut<TodoListCommon>(@todolist_addr);
    let resource_signer = account::create_signer_with_capability(&commonTodoList.signer_cap);
    let signer_address= signer::address_of(&resource_signer);
    event::counter(&borrow_global<TodoListCommon>(signer_address).set_task_event)
  }

  #[test_only]
  public(friend) entry fun getCommonTaskCounter(admin: &signer):u64 acquires TodoListCommon{
    let commonTodoList= borrow_global_mut<TodoListCommon>(@todolist_addr);
    let resource_signer = account::create_signer_with_capability(&commonTodoList.signer_cap);
    let signer_address= signer::address_of(&resource_signer);
    borrow_global<TodoListCommon>(signer_address).task_counter
  }

  #[test_only]
  public(friend) entry fun getCommonTaskRecord(admin: &signer):(u64,bool,String,address) acquires TodoListCommon{
    let commonTodoList= borrow_global_mut<TodoListCommon>(@todolist_addr);
    let resource_signer = account::create_signer_with_capability(&commonTodoList.signer_cap);
    let signer_address= signer::address_of(&resource_signer);
    let task_record=table::borrow(&commonTodoList.tasks,commonTodoList.task_counter);
    (task_record.task_id,task_record.completed,task_record.content,task_record.address)
  }

  #[test_only]
  public(friend) entry fun callCommonInit(admin: &signer) {
    init_module(admin)
  }

}