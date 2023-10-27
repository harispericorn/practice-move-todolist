
#[test_only]
module todolist_addr::unit_tests{
    use aptos_framework::event;
    use std::signer;
    use aptos_framework::account;
    use std::string::{Self, String};
    use todolist_addr::todolist;
    use aptos_framework::resource_account;

    #[test (admin=@0x123)]
    fun test_flow(admin:&signer) {
        account::create_account_for_test(signer::address_of(admin));
        todolist::create_list(admin);

        todolist::create_task(admin,string::utf8(b"New Task"));
        let task_count= todolist::getEventCount(admin);
        let task_count_from_resource= todolist::getTaskCounter(admin);
        assert!(task_count == 1, 4);
        assert!(task_count_from_resource==1,5);
        let (id,completed,content,addr)= todolist::getTaskRecord(admin);
        assert!(id==1,10);
        assert!(completed==false,11);
        assert!(content== string::utf8(b"New Task"),12);
        assert!(addr== signer::address_of(admin),13);
        // complete task
        todolist::complete_task(admin, 1);

        let (id,completed,content,addr)= todolist::getTaskRecord(admin);
        assert!(id==1,10);
        //everything else same completed flag will become true
        assert!(completed==true,11);
        assert!(content== string::utf8(b"New Task"),12);
        assert!(addr== signer::address_of(admin),13);
       

    }

    public(friend) fun setup_test(
       origin: &signer,
       resource: &signer,
     
    )  {
        account::create_account_for_test(signer::address_of(origin));
        account::create_account_for_test(signer::address_of(resource));
        let seed = x"01";
        let (resource1, resource_signer_cap) = account::create_resource_account(origin, seed);
        let resource1_addr = signer::address_of(&resource1);
        todolist::init_test(resource, resource_signer_cap);
    }

    

    #[test(origin_account = @source_addr, resource_account = @todolist_addr)]
    fun test_resource_flow(origin_account: signer, resource_account: signer) {
        setup_test(&origin_account, &resource_account);
        todolist::create_common_task(&origin_account,string::utf8(b"New Task"));
        let task_count= todolist::getCommonEventCount(&origin_account);
        let task_count_from_resource= todolist::getCommonTaskCounter(&origin_account);
        assert!(task_count == 1, 4);
        assert!(task_count_from_resource==1,5);
        let (id,completed,content,addr)= todolist::getCommonTaskRecord(&origin_account);
        assert!(id==1,10);
        assert!(completed==false,11);
        assert!(content== string::utf8(b"New Task"),12);
        assert!(addr== signer::address_of(&origin_account),13);
        // complete task
        todolist::complete_common_task(&origin_account, 1);

        let (id,completed,content,addr)= todolist::getCommonTaskRecord(&origin_account);
        assert!(id==1,10);
        //everything else same completed flag will become true
        assert!(completed==true,11);
        assert!(content== string::utf8(b"New Task"),12);
        assert!(addr== signer::address_of(&origin_account),13);
       

    }

    #[test(origin_account = @source_addr, resource_account = @todolist_addr)]
    fun test_resource_with_multi_task(origin_account: signer, resource_account: signer) {
        setup_test(&origin_account, &resource_account);
        todolist::create_common_task(&origin_account,string::utf8(b"New Task"));
        todolist::create_common_task(&origin_account,string::utf8(b"New Task2"));
        let (id,completed,content,addr)= todolist::getCommonTaskRecord(&origin_account);
        assert!(id==2,10);
        assert!(completed==false,11);
        assert!(content== string::utf8(b"New Task2"),12);
        assert!(addr== signer::address_of(&origin_account),13);
    }


    #[test (origin_account = @source_addr, resource_account = @todolist_addr, framework = @aptos_framework)]
    #[expected_failure(abort_code=2)]
    fun cannot_update_inintialized_task(origin_account: signer, resource_account: signer,){
        setup_test(&origin_account, &resource_account);
        todolist::complete_common_task(&origin_account, 1);
    }
    
}