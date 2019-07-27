/*****************************************
  To complete the upgrade process
 *****************************************/
#include "download.h"
#include "file.h"
#include <stdio.h>
#include <stdarg.h>
#include <string.h>
#include<time.h>
#include <stdlib.h>
#include "os_linux.h"
#include "serialif.h"
#include "qcn.h"

#include <stdio.h>
#include <ctype.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>
#include<sys/time.h>

FILE *log_file;  //Log Handle define
int g_port_temp=0;
int g_upgrade_fastboot=0;
int g_upgrade_fastboot_last=0;

timeval start,end;
long dif_sec,dif_usec;
int show_min;
int show_sec;
int show_msec;
int show_usec;
int ret;

static pid_t udhcpc_pid = 0;

vector<Ufile>::iterator iter; 
byte boot_tmp_crc_table[1024*4]={0};
byte *boot_tmp=boot_tmp_crc_table;
int boot_tmp_datasize = sizeof(boot_tmp_crc_table);

int create_log(void) {
    struct tm *ptm;
    long ts;
    int y, m, d, h, n, s;
    ts = time(NULL);
    ptm = localtime(&ts);
    y = ptm->tm_year + 1900; //???
    m = ptm->tm_mon + 1; //???
    d = ptm->tm_mday; //???
    h = ptm->tm_hour; //???
    n = ptm->tm_min; //???
    s = ptm->tm_sec; //???
    char filename[200];
    sprintf(filename, "UPGRADE%d%02d%02d%02d%02d%02d.log", y, m, d, h, n, s);
    printf("Log name is %s\n", filename);
    log_file = fopen(filename, "wt");
    return (log_file != NULL);
}

void get_time_to_show(timeval start,timeval end)
{
	dif_sec = end.tv_sec - start.tv_sec;
	dif_usec = end.tv_usec - start.tv_usec;
	if(dif_usec>=1000)
	{
		show_msec = dif_usec/1000;
		show_usec = dif_usec%1000;
	}
	if(dif_sec >= 60)	
	{		
		show_min = dif_sec/60;		
		show_sec = dif_sec%60; 	
		if(show_min>=3)
		{
			printf(" THE TOTAL DOWNLOAD TIME IS %dmin : %ds : %dms :  %dus\n",show_min,show_sec,show_msec,show_usec);
			return;
		}
		printf("The file download time is %dmin : %ds : %dms : %dus\n",show_min,show_sec,show_msec,show_usec);
	}	
	if(dif_sec < 60)
	{	
			
			printf("The file download time is %lds : %dms : %dus\n",dif_sec,show_msec,show_usec);
	}


}
int close_log(void) {
    if (log_file != NULL)
        fclose(log_file);
    log_file = NULL;
    return TRUE;
}
int save_log(const char *fmt,...)
{
    va_list args;
    int len;
    int result = false;
    struct tm *ptm;
    long ts;
    int y, m, d, h, n, s;
    ts = time(NULL);
    ptm = localtime(&ts);
    y = ptm->tm_year + 1900; //???
    m = ptm->tm_mon + 1; //???
    d = ptm->tm_mday; //???
    h = ptm->tm_hour; //???
    n = ptm->tm_min; //???
    s = ptm->tm_sec; //???
    char* newfmt = (char*) malloc(strlen(fmt) + 30);
    sprintf(newfmt, "[%d-%02d-%02d %02d:%02d:%02d]%s", y, m, d, h, n, s, fmt);
    va_start(args, fmt);
    
    char* buffer = (char*) malloc(500);
    vsprintf(buffer, newfmt, args);
    strcat(buffer, "\r\n");
    va_end(args);
    free(newfmt);
    newfmt = NULL;

    if (buffer == NULL)
        return result;

    //printf("%s", buffer);   

    if (log_file != NULL) {
        int result = fwrite((void *) buffer, sizeof(char),
                strlen((const char *) buffer), log_file);
        free(buffer);
        buffer = NULL;
        fflush(log_file);
        result = true;
    }
    return result;
}

int ProcessInit(qdl_context *pQdlContext) {
    pQdlContext->logfile_cb = save_log;
    if (!image_read(pQdlContext)) {
        printf("Parse file error\n");
        return 0;
    }
    return 1;
}

int ProcessUninit(qdl_context *pQdlContext) {
    close_log();
    image_close(pQdlContext);
    return 1;
}

int module_state(qdl_context *pQdlContext)
{
    pQdlContext->text_cb("Module Status Detection");
    int timeout = 5;
    while (timeout--) {
        pQdlContext->TargetState = send_sync();
        if (pQdlContext->TargetState == STATE_UNSPECIFIED) {
            if (timeout == 0) {
                pQdlContext->text_cb(
                        "Module status is unspecified, download failed!");
                pQdlContext->logfile_cb(
                        "Module status is unspecified, download failed!");
                return FALSE;
            }
            pQdlContext->logfile_cb("Module state is unspecified, try again");
            qdl_sleep(2000);
        } else {
            break;
        }
    }
    return TRUE;
}
static FILE * ql_popen(const char *program, const char *type)
{
	FILE *iop;
	int pdes[2];
	pid_t pid;
	char *argv[20];
	int argc = 0;
	char *dup_program = strdup(program);
	char *pos = dup_program;

	while (*pos != '\0')
	{
		while (isblank(*pos)) *pos++ = '\0';
		if (*pos != '\0')
		{
			argv[argc++] = pos;
			while (*pos != '\0' && !isblank(*pos)) pos++;
			//dbg_time("argv[%d] = %s", argc-1, argv[argc-1]);
		}
	}
	argv[argc++] = NULL;

	if (pipe(pdes) < 0) {
		return (NULL);
	}

	switch (pid = fork()) {
	case -1:			/* Error. */
		(void)close(pdes[0]);
		(void)close(pdes[1]);
		return (NULL);
		/* NOTREACHED */
	case 0: 			   /* Child. */
		{
		if (*type == 'r') {
			(void) close(pdes[0]);
			if (pdes[1] != STDOUT_FILENO) {
				(void)dup2(pdes[1], STDOUT_FILENO);
				(void)close(pdes[1]);
			}
		} else {
			(void)close(pdes[1]);
			if (pdes[0] != STDIN_FILENO) {
				(void)dup2(pdes[0], STDIN_FILENO);
				(void)close(pdes[0]);
			}
		}
		execvp(argv[0], argv);
		_exit(127);
		/* NOTREACHED */
		}
		   break;
	   default:
			udhcpc_pid = pid;
			free(dup_program);
	   break;
	}

	/* Parent; assume fdopen can't fail. */
	if (*type == 'r') {
		iop = fdopen(pdes[0], type);
		(void)close(pdes[1]);
	} else {
		iop = fdopen(pdes[1], type);
		(void)close(pdes[0]);
	}

	return (iop);
}



static int ql_pclose(FILE *iop)
{
	(void)fclose(iop);
	udhcpc_pid = 0;
	return 0;
}

int open_port_operate()
{
    int timeout = 5;
    while (timeout--) {
        qdl_sleep(1000);
        if (!openport()) {
            qdl_sleep(1000);
            if (timeout == 0) {

                return 0;
            } else
                continue;
        } else {
            return 1;
            break;
        }
    }
}


int probe_quectel_speed(enum usb_speed* speed)
{
	FILE* fpin1 = 0, *fpin2 = 0;
	FILE* fpin3 = 0;
	char *line = (char*)malloc(MAX_PATH);
	char *command = (char*)malloc(MAX_PATH + MAX_PATH + 32);	
	char *p = 0;
	char devicename[50];
	int ret = 1;

	sprintf(command, "ls /sys/bus/usb/devices/");
	fpin1 = ql_popen(command, "r");
	if(!fpin1)	goto _exit_;

	while(fgets(line, MAX_PATH - 1, fpin1) != NULL)
	{		
		p = line;
		while(*p != '\n' && p != NULL) p++;
		*p = 0;			
		sprintf(command, "cat /sys/bus/usb/devices/%s/idVendor", line);
		if(strlen(p) < 49)
		{
			memset(devicename, 0, 50);
			strcpy(devicename, line);
		}
		fpin2 = ql_popen(command, "r");
		if(!fpin2) goto _exit_;
		
		while(fgets(line, MAX_PATH - 1, fpin2) != NULL)
		{		
			if(strstr(line, "2c7c") != NULL)
			{
				printf("find Quectel device!\n");
				p = line;
				while(*p != '\n' && p != NULL) p++;
				*p = 0;	
				sprintf(command, "cat /sys/bus/usb/devices/%s/speed", devicename);
				fpin3 = ql_popen(command, "r");
				if(!fpin3) goto _exit_;
				if(fgets(line, MAX_PATH - 1, fpin3) != NULL)
				{ // refer to :http://stackoverflow.com/questions/1957589/usb-port-speed-linux
					printf("speed = %s", line);
					if(strstr(line, "480") != NULL)
					{
						*speed = usb_highspeed;
					}
					else if(strstr(line, "12") != NULL ||
							strstr(line, "1.5") != NULL)
					{
						*speed = usb_fullspeed;
					}else
					{
						*speed = usb_superspeed;
					}
					ret = 0;
					goto _exit_;
				}				
			}
			fclose(fpin3); fpin3 = 0;
		}
		fclose(fpin2); fpin2 = 0;
	}
_exit_:
	if(line)
	{
		free(line);line = 0;
	}
	if(command)
	{
		free(command); command = 0;
	}
	if(fpin1)
	{
		fclose(fpin1);
	}
	if(fpin2)
	{
		fclose(fpin2);
	}
	if(fpin3)
	{
		fclose(fpin3);
	}
	return ret;
}



static int do_flash_mbn(const char *partion, const char *filepath) {
    char *program = (char *) malloc(MAX_PATH + MAX_PATH + 32);
    int result;
    byte *filebuf;
    uint32 filesize;
    FILE * fp = NULL;

    if (!program) {
        printf("fail to malloc memory for %s %s\n", partion, filepath);
        return 0;
    }

    sprintf(program, "flash %s %s", partion, filepath);
    printf("%s\n", program);
    if(strstr(filepath, "invalid-boot") != NULL)
	{
		filebuf = boot_tmp;
		filesize = boot_tmp_datasize;
	}
    else
    {
	    if (!partion || !filepath || !filepath[0] || access(filepath, R_OK)) 
	    {
	        free(program);
	        return 0;
	    }

#if 0
	    filebuf = open_file(filepath, &filesize);
	    if (filebuf == NULL) {
	        free(program);
	        return FALSE;
	    }
#else
	    filebuf = (byte *)malloc(4*1024);
	    if (filebuf == NULL) {
	        free(program);
	        return FALSE;
	    }

	    fp = fopen(filepath, "r");
	    if (fp == NULL) {
	        printf("%s(%s) failed to fopen errno: %d (%s)\n", __func__, filepath, errno, strerror(errno));
	        return 0;
	    }
	    
	    fseek(fp, 0, SEEK_END);
	    filesize = ftell(fp);
	    fseek(fp, 0, SEEK_SET);
#endif
    }

    strcpy(program, partion);
    result = handle_openmulti(strlen(partion) + 1, (byte *)program);
    if (result == false) {
        printf("%s open failed\n", partion);
    	fclose(fp); free(filebuf); filebuf = NULL;
        goto __fail;
    }

    sprintf(program, "sending '%s' (%dKB)", partion, (int)(filesize/1024));
    printf("%s\n", program);

    //result = handle_write(filebuf, filesize);
    result = handle_write(fp, filebuf, filesize);
    if(fp!=NULL){
        fclose(fp); free(filebuf); filebuf = NULL;
	}
    if (result == false) {
        QdlContext->text_cb("");
        QdlContext->text_cb("%s download failed", partion);
        goto __fail;
    }

    result = handle_close();
    if (result == false) {
        QdlContext->text_cb("%s close failed", partion);
        goto __fail;
    }

    printf("OKAY\n");

    free(program);
    if(fp != NULL){
		free_file(filebuf, filesize);
	}
    return TRUE;

__fail:
    free(program);
    if(fp!=NULL){
		free_file(filebuf, filesize);
	}
    return FALSE;
}

static int do_fastboot(const char *cmd, const char *partion, const char *filepath) {
	char *program = (char *) malloc(MAX_PATH + MAX_PATH + 32);
	char *line = (char *) malloc(MAX_PATH);
	char *self_path = (char *) malloc(MAX_PATH);
	FILE * fpin;
	
	int self_count = 0;
	int recv_okay = 0;
	int recv_9607 = 0;

	if (!program || !line || !self_path) {
		printf("fail to malloc memory for %s %s %s\n", cmd, partion, filepath);
		return 0;
	}

	self_count = readlink("/proc/self/exe", self_path, MAX_PATH - 1);
	if (self_count > 0) {
		self_path[self_count] = 0;
	} else {
		printf("fail to readlink /proc/self/exe for %s %s %s\n", cmd, partion, filepath);
		return 0;
	}
	
	if (!strcmp(cmd, "flash")) {
		if (!partion || !partion[0] || !filepath || !filepath[0] || access(filepath, R_OK)) {
			free(program);;free(line);free(self_path);
			return 0;
		}
		sprintf(program, "%s fastboot %s %s %s", self_path, cmd, partion, filepath);
	  // sprintf(program, "%s fastboot %s %s %s 1>2 2>./rfastboot", self_path, cmd, partion, filepath);
		
	} else {
		sprintf(program, "%s fastboot %s", self_path, cmd);
		//sprintf(program, "%s fastboot %s 1>./rfastboot", self_path, cmd);
	}

	printf("%s\n", program);

	fpin = ql_popen(program, "r");


	if (!fpin) {
		printf("popen failed\n");
		printf("popen strerror: %s\n", strerror(errno));
		return 0;
	}

	while (fgets(line, MAX_PATH - 1, fpin) != NULL) {
		printf("%s", line);
		if (strstr(line, "OKAY")) {
			recv_okay++;
		} else if (strstr(line, "fastboot")) {
			recv_9607++;
		}
	}
	
	ql_pclose(fpin);
	free(program);free(line);free(self_path);
	if (!strcmp(cmd, "flash"))
		return (recv_okay == 2);
	else if (!strcmp(cmd, "devices"))
		return (recv_9607 == 1);
   else if (!strcmp(cmd, "continue"))
		return (recv_okay == 1);
   else
		return (recv_okay > 0);
	
	return 0;
}

int BFastbootModel() {
	return do_fastboot("devices", NULL, NULL);
}



int downloadfastboot(qdl_context *pQdlContext) {
	for (iter=pQdlContext->ufile_list.begin();iter!=pQdlContext->ufile_list.end();iter++) 
	{
		if(strcmp("0:MIBIB",((Ufile)*iter).name)!=0)
		{			
#if 0
			if(strstr(((Ufile)*iter).name,"0:modem") != NULL)
				do_fastboot("flash","modem",((Ufile)*iter).img_name);
			
			if(strstr(((Ufile)*iter).name,"0:recovery") != NULL&&strstr(((Ufile)*iter).name,"0:recoveryfs") == NULL)         
				do_fastboot("flash","recovery",((Ufile)*iter).img_name);
      
			if(strstr(((Ufile)*iter).name,"0:recoveryfs") != NULL)
				do_fastboot("flash","recoveryfs",((Ufile)*iter).img_name);
			
			if(strstr(((Ufile)*iter).name,"0:sys_back") != NULL)
				do_fastboot("flash","sys_back",((Ufile)*iter).img_name);

			if(strstr(((Ufile)*iter).name,"0:system") != NULL)
				do_fastboot("flash","system",((Ufile)*iter).img_name);	

            if(strstr(((Ufile)*iter).name,"0:EFS2") != NULL)
				do_fastboot("flash","efs2",((Ufile)*iter).img_name);	
       
			if(strstr(((Ufile)*iter).name,"0:boot") != NULL)
				do_fastboot("flash","boot",((Ufile)*iter).img_name);
#else
			do_fastboot("flash",(*iter).partition_name,((Ufile)*iter).img_name);
#endif
		}
			
	}
	do_fastboot("reboot", NULL, NULL);
	return TRUE;
}


//MDM9607	
int downloading(qdl_context *pQdlContext)
{
	int sync_timeout=15;
	int timeout = 10;
	int helloflag=0;
	int re;
    if (pQdlContext->update_method == 0 && BFastbootModel()) {
		printf("fastboot module\n");
		goto fastboot_download;
	}
    //open port
    if(open_port_operate() == 0)
    {
        pQdlContext->text_cb("Start to open port, Failed!");
        return FALSE;
    }

	/***************slove emergency down power:reopen port**********************/
	if(open_flag==1)
	{
		closeport(g_hCom);
	   qdl_sleep(5000);
	   timeout = 10;
	   while (timeout--) {
	   //	 closeport(g_hCom);
		   if (!openport()) {
			   if (timeout == 0) {
				   QdlContext->text_cb("Send switch to dload command failed, download error!");
				   return FALSE;
			   } else
				   continue;
		   }
		   else
			   break;
	   }
		
	}
	pQdlContext->text_cb("Get Hello response packet!");
	//读取串口缓冲区内容，查看是否是HELLO PACKET
	ret=GetHelloPacket();
	if(ret==true)
	{
		helloflag=1;
		goto SAHARA_HELLO_RESPONSE;
	}
	pQdlContext->text_cb("Get Hello response packet failed,now change the status!");
 
    if(pQdlContext->update_method==2||pQdlContext->update_method==4)
    {
        pQdlContext->text_cb("Sp unlocked...");
        if (handle_send_sp_code() != 1) {
            pQdlContext->text_cb("Sp unlocked failed");
            qdl_sleep(200);
            return FALSE;
        }

        pQdlContext->text_cb("Backup QQB...");
        if (SaveQqbThreadFunc(pQdlContext) == false) {
            remove("backup.qqb");
            pQdlContext->text_cb("");
            pQdlContext->text_cb("Backup failed");

            return FALSE;
        }
        if(pQdlContext->update_method==2)
            return TRUE;
    }
	if(pQdlContext->update_method==3)
	{
		goto __QQBRESTOR;
	}
    //+++++++++++++++++++++++++++
    /* pQdlContext->text_cb("Get Hello packet!");
       if(GetHelloPacket()!=false)
       {
       downloadtype=1;
       goto Emergency_download;
       }*/
	//探测模块的当前状态
    if (module_state(pQdlContext) == 0)//??取模????状态
    {
        return FALSE;
    }
    if (pQdlContext->TargetState == STATE_NORMAL_MODE) {
        qdl_sleep(50);
        QdlContext->text_cb("Switch to PRG status");
        //切换模块的工作模式，正常模式到下载模式
        //3.4.55 Switch to Downloader(58/0x3A) 80-V1294-1_YU_DMSS_Serial_Data_ICD.pdf
        if (switch_to_dload() == false) {
            QdlContext->text_cb("Switch to PRG status failed");
            return FALSE;
        }
		if(tcp_flag)
		{
			usleep(3000);  //tcp send data finished,then close port;
		}	
        closeport(g_hCom);
        qdl_sleep(10000);
        int timeout = 10;
        while (timeout--) {
        //    closeport(g_hCom);
            if (!openport()) {
                if (timeout == 0) {
                    QdlContext->text_cb("Send switch to dload command failed, download error!");
                    return FALSE;
                } else
                    continue;
            }
            else
                break;
        }
    }
    else if(pQdlContext->TargetState == STATE_SAHARA_MODE)
    {
        goto SAHARA_download;
    }
    else if(pQdlContext->TargetState == STATE_ENDOFIMG_MODE)
    {
    	if(SendResetPacket() == false)
	    {
	        pQdlContext->text_cb("Send Do packet failed!");
	        return FALSE;
	    }

	    closeport(g_hCom);
        qdl_sleep(10000);
        int timeout = 10;
        while (timeout--) {
            if (!openport()) {
                if (timeout == 0) {
                    QdlContext->text_cb("Send switch to dload command failed, download error!");
                    return FALSE;
                } else
                    continue;
            }
            else
                break;
        }
    }
    else if (pQdlContext->TargetState == STATE_GOING_MODE)
    {
        goto __STATE_GOING_MODE;
    }
    else
    {
        pQdlContext->text_cb("Get Hello packet failed!");
        return FALSE;
    }
SAHARA_download:
	pQdlContext->text_cb("Get Hello response packet!");
	if(GetHelloPacket()==false)
	{
		pQdlContext->text_cb("Get Hello response packet failed!");
	}
    //2.send hello response packet

SAHARA_HELLO_RESPONSE:
    
	if(helloflag==1)
	{
		helloflag=0;
		pQdlContext->text_cb("Send Hello response packet again!");
		if(SendHelloPacket()==false)
		{
			pQdlContext->text_cb("Send Hello response packet failed!");
			return FALSE;
		}
	}
    else{
		pQdlContext->text_cb("Send Hello response packet!");
		if(SendHelloPacketTest()==false)
		{
			pQdlContext->text_cb("Send Hello response packet failed!");
			return FALSE;
		}
	}

    //3.Get Read Data packet
    pQdlContext->text_cb("Start Read Data!");
    //sahara 协议 GET_DATA_PACKET
    //这里会上传一个文件到模块里面，文件的内容就是模块内部实现的升级协议，上传后，重启模块，然后模块会运行这个文件的
    //代码，这样就可以升级了
	re=GetReadDataPacket();
	if(re==2)
	{
		helloflag=1;
		goto SAHARA_HELLO_RESPONSE;
	}
		
    if(re==false)
    {
        return FALSE;
    }
    pQdlContext->text_cb("Send Do packet!");
    //Sahara Done 包 80-N1008-1_SAHARA PROTOCOL SPECIFICATION.pdf
    if(SendDoPacket()==false)
    {
        pQdlContext->text_cb("Send Do packet failed!");
        return FALSE;
    }
    pQdlContext->text_cb("Module Status Detection");
    //check module's mode
    if(tcp_flag)
	{
		usleep(3000);  
	}	
    closeport(g_hCom);
    qdl_sleep(5000);
  
    while (timeout--) {
        //closeport(g_hCom);
        if (!openport()) {
            if (timeout == 0) {
                QdlContext->text_cb("Open port failed!");
                return FALSE;
            } else
            {
                qdl_sleep(5000);
                continue;
            }

        }
        else
            break;
    }
    //再次探测模块的状态
    while (sync_timeout--) {
        pQdlContext->TargetState = send_sync();
        if (pQdlContext->TargetState != STATE_UNSPECIFIED) {
            break;
        } else if (sync_timeout > 0) {
        	if(tcp_flag)
			{
				usleep(3000);  
			}
            closeport(g_hCom);
            qdl_sleep(4000);
            if (open_port_operate() == 0) 
            {
                pQdlContext->text_cb("Start to open port, Failed!");
                pQdlContext->logfile_cb("Start to open port, Failed!");
                return FALSE;
            }
            continue;
        } else if (sync_timeout == 0) {
            pQdlContext->text_cb("Sync Timeout, Failed!");
            return FALSE;
        }
    }

__STATE_GOING_MODE:
    if (pQdlContext->TargetState == STATE_GOING_MODE) {
        pQdlContext->text_cb("Start to download firmware");
        pQdlContext->logfile_cb("hello");
        if (handle_hello() == false) {
            pQdlContext->text_cb("Send hello command fail");
            pQdlContext->logfile_cb("Send hello command fail");
            return FALSE;
        } 

        if (handle_security_mode(1) == false) {
            pQdlContext->text_cb("Send trust command fail");
            pQdlContext->logfile_cb("Send trust command fail");
            return FALSE;
        }

        if (handle_parti_tbl(0) == false) {
            pQdlContext->text_cb("Partitbl mismatched");
            pQdlContext->logfile_cb("Partitbl mismatched");
        }

		//上传实际的文件到模块，do_flash_mbn 参考streaming_download_protocol_specification.pdf
        if(pQdlContext->update_method == 0)  //fastboot module
		{
		    pQdlContext->text_cb("change to fastboot mode...");            
            for (iter=pQdlContext->ufile_list.begin();iter!=pQdlContext->ufile_list.end();/*iter++*/) 
	        {
	        	if(strcmp("0:MIBIB",((Ufile)*iter).name)!=0)
			    {
			        if(strstr(((Ufile)*iter).name,"0:aboot") != NULL)
				    {
				    	do_flash_mbn(((Ufile)*iter).name, ((Ufile)*iter).img_name);
				    	iter = pQdlContext->ufile_list.erase(iter);
			        }else if(strstr(((Ufile)*iter).name,"0:SBL") != NULL)
				    {
				    	do_flash_mbn(((Ufile)*iter).name, ((Ufile)*iter).img_name);
				    	iter = pQdlContext->ufile_list.erase(iter);
			        }else if(strstr(((Ufile)*iter).name,"0:RPM") != NULL)
				    {
				    	do_flash_mbn(((Ufile)*iter).name, ((Ufile)*iter).img_name);
				    	iter = pQdlContext->ufile_list.erase(iter);
			        }else if(strstr(((Ufile)*iter).name,"0:TZ") != NULL)
				    {
				    	do_flash_mbn(((Ufile)*iter).name, ((Ufile)*iter).img_name);
				    	iter = pQdlContext->ufile_list.erase(iter);
			        }
			        else
			        {
			        	iter++;
			        }
			    }else
			    {
			    	iter++;
			    }
	        }            
            do_flash_mbn("0:boot", "invalid-boot");  //write invalid boot for run fastboot
            qdl_sleep(1000);
            //这里走的协议叫做streaming download protocol 协议，看协议文档里面复位操作 handle_reset完成
            //到这里就借本结束了
			if (handle_reset() == false) {
				pQdlContext->text_cb("Send reset command failed");
				pQdlContext->logfile_cb("Send reset command failed");
				return FALSE;
			}
			closeport(g_hCom);
			qdl_sleep(5000);
			goto fastboot_download;
		}
        else
        {
	        for (iter=pQdlContext->ufile_list.begin();iter!=pQdlContext->ufile_list.end();iter++)  
	        {  
	            if(strcmp("0:MIBIB",((Ufile)*iter).name)!=0)
				{
					gettimeofday(&start,NULL);
					ret=do_flash_mbn(((Ufile)*iter).name, ((Ufile)*iter).img_name);
					gettimeofday(&end,NULL);
					get_time_to_show(start,end);
					if(ret==false)
					{
						pQdlContext->text_cb("down file:%s is faliled\n",((Ufile)*iter).name);
						return FALSE;
					}
				}
	        }
        }

    }
    qdl_sleep(1000);
    if (handle_reset() == false) {
        pQdlContext->text_cb("Send reset command failed");
        pQdlContext->logfile_cb("Send reset command failed");
        return FALSE;
    }
	if(tcp_flag)
	{
		usleep(3000);  
	}
    closeport(g_hCom);
    qdl_sleep(10000);
    timeout = 10;
    while (timeout--) {
      //  closeport(g_hCom);
        if (!openport()) {
            qdl_sleep(1000);
            if (timeout == 0) {
                pQdlContext->text_cb("Open to com port failed...");
                return FALSE;
            } else
                continue;
        } else
            break;
    }
__QQBRESTOR:
    if(pQdlContext->update_method == 4
            || pQdlContext->update_method == 3)
    {
		qdl_sleep(2000);
        if (handle_switch_target_ftm() != 1) {

            pQdlContext->text_cb("Switch offline mode failed");
            qdl_sleep(200);
            return FALSE;
        }
        if (handle_send_sp_code() != 1) {
            pQdlContext->text_cb("Sp unlocked failed");
            qdl_sleep(200);
            return FALSE;
        }
		if(pQdlContext->qqb_EC20!=NULL)
		{
			pQdlContext->text_cb("QQB downloading...");
			if (Import_Qqb_Func(pQdlContext) == false) {
				pQdlContext->text_cb("QQB download failed");
				return FALSE;
			}
		}
        pQdlContext->text_cb("Restore QQB...");
        pQdlContext->logfile_cb("Restore QQB...");
        if (RestoreQqbThreadFunc(pQdlContext) == false) {
            pQdlContext->text_cb("");
            pQdlContext->text_cb("Restore QQB fail");
            pQdlContext->logfile_cb("Restore QQB fail");
            return FALSE;
        }
    }
    normal_reset();
fastboot_download:
	if(pQdlContext->update_method == 0)  
	{
		if(BFastbootModel())
		{
			if(downloadfastboot(pQdlContext)== FALSE)
			{
				return FALSE;
			}
		}
        else
            return FALSE;
            
	}
    pQdlContext->text_cb("the device restart...");
	pQdlContext->text_cb(" ");
	pQdlContext->text_cb("Wlecome to use the Quectel module!!!");
    return TRUE;
}


