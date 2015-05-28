log_time_table0.txt: table0.grace cp_obj.grace ../../minigrace ./time_table0.sh
	$(MAKE) clean
	../../minigrace cp_obj.grace
	./time_table0.sh >> log_time_table0.txt

clean: 
	-rm *.gso *.gcn *.gct *.c -f
