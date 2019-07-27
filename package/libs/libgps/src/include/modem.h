#ifndef MODEM_H
#define MODEM_H

// Supported modems.
typedef enum {
	HE910,
	LE910,
	ME909U,
	ME909S,
	EM820W,
	MC7354,
	EC20,
	MT421,
	ME936
} modem_dev;


unsigned int get_modem(void);

#endif
