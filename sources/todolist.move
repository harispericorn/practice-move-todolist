module todolist_addr::todolist {

  #[test_only]
  friend todolist_addr::unit_tests;
  
  use aptos_framework::event;
  use std::string::String;
  use std::signer;
  use aptos_std::table::{Self, Table}; 
  use aptos_framework::account;
  
  struct TodoList has key {
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

  public entry fun create_list(account: &signer){
    let task_holder= TodoList{
        tasks: table::new(),
        set_task_event: account::new_event_handle<Task>(account),
        task_counter: 0
    };
    move_to(account,task_holder)
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

}