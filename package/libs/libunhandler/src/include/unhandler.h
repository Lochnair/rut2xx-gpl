//
// Created by simonas on 16.5.19.
//
/*****************************************
 * 	Remastered
 *****************************************/
#ifndef UNHANDLER_H
#define UNHANDLER_H

#include "lock.h"
#include "getpid.h"
	
/*****************************************
 * 	main unsolicited functions
 *****************************************/
void unsolicited_simstate_keeper(char *arg);
void unsolicited_simstate_keeper_huawei(char *arg);
void unsolicited_netstate_keeper(char *arg);
void unsolicited_netstate_keeper_huawei(char *arg);
void unsolicited_conntype_keeper(char *arg);
void unsolicited_conntype_keeper_huawei(char *arg);
void unsolicited_conntype_keeper_sierra(char *arg);
void unsolicited_conntype_keeper_EC20(char *arg);
void SMS_script(char *arg);

void Calling_telit(char *arg);
int interface_hotplug_event(char *arg);
void check_connection_type(char *arg);
void log_connection_event(char *event);
void Roaming(char *arg);
void unhandler(const char *argumentas);
char *get_interface_ip(char * interface);

/**********
 * helper.h
 **********/
void insert_into_events(char *tabl, char *typ, char *txt);
char *get_operator_from_socket(void);

int save_state(char *name, char *value, char *file); 

/**********
 * signal_str.h
 **********/
void check_the_rules(int strength);
void event_and_restrict(struct uci_context *uci, char *restr_time, char *block, int dbm);
void signal_script(char *arg);
void signal_huawei(char *arg);
void signal_quectel(char *arg);
void signal_quectel_EC20(char *arg);
void signal_telit(char *arg);

/**********
 * operator.h
 **********/
void write_operator_to_file(const char *operator);
void read_operator_from_file(char *operator, int len);
void operator_log(int renew);

#endif
