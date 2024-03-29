#
# Copyright (C) 2011-2013 OpenWrt.org
# Copyright (C) 2010 Jo-Philipp Wich <xm@subsignal.org>
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=mosquitto
PKG_VERSION:=1.4.15
PKG_RELEASE:=3
PKG_LICENSE:=BSD-3-Clause
PKG_LICENSE_FILES:=LICENSE.txt

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=http://mosquitto.org/files/source/
PKG_MD5SUM:=546cb1ce35cc3f7d23e6d2f1f9a962e7
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(BUILD_VARIANT)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/mosquitto/default
  SECTION:=net
  CATEGORY:=Network
  TITLE:=mosquitto - an MQTT message broker
  URL:=http://www.mosquitto.org/
  MAINTAINER:=Karl Palsson <karlp@etactica.com>
  DEPENDS:= +librt +libuuid
  USERID:=mosquitto=200:mosquitto=200
endef

define Package/mosquitto-ssl
    $(call Package/mosquitto/default)
    TITLE+= (with SSL support)
    DEPENDS+= +libopenssl +MOSQUITTO_LWS:libwebsockets-openssl
    VARIANT:=ssl
    PROVIDES:=mosquitto
endef

define Package/mosquitto-nossl
    $(call Package/mosquitto/default)
    TITLE+= (without SSL support)
    VARIANT:=nossl
    PROVIDES:=mosquitto
endef

define Package/mosquitto-ssl/config
	source "$(SOURCE)/Config.in"
endef

define Package/mosquitto/default/description
Mosquitto is an open source (BSD licensed) message broker that implements
the MQTT protocol version 3.1 and 3.1.1. MQTT provides a lightweight
method of carrying out messaging using a publish/subscribe model.

This package also includes some basic support for configuring via UCI
endef

define Package/mosquitto-ssl/description
	$(call Package/mosquitto/default/description)
This package is built with SSL support.  TLS-PSK will be included (in both
the client and broker) if OpenSSL is built with TLS-PSK support.
endef

define Package/mosquitto-nossl/description
        $(call Package/mosquitto/default/description)
        This package is built WITHOUT SSL support.
endef


define Package/mosquitto-client/default
    $(Package/mosquitto/default)
    TITLE:= mosquitto - client tools
    DEPENDS+=+libcares
    PROVIDES:=mosquitto-client
endef
define Package/mosquitto-client-ssl
    $(call Package/mosquitto-client/default)
    TITLE+= (With SSL support)
    DEPENDS+=+libmosquitto-ssl
    VARIANT:=ssl
endef
define Package/mosquitto-client-nossl
    $(call Package/mosquitto-client/default)
    TITLE+= (Without SSL support)
    DEPENDS+=+libmosquitto-nossl
    VARIANT:=nossl
endef

define Package/mosquitto-client/default/description
 Command line client tools for publishing messages to MQTT servers
and subscribing to topics.
endef

define Package/mosquitto-client-ssl/description
$(call Package/mosquitto-client/default/description)
        This package is built with SSL support
endef
define Package/mosquitto-client-nossl/description
$(call Package/mosquitto-client/default/description)
        This package is built without SSL support
endef

define Package/libmosquitto/default
    $(Package/mosquitto/default)
    SECTION:=libs
    CATEGORY:=Libraries
    DEPENDS:=+libpthread +librt +libcares
    TITLE:= mosquitto - client library
    PROVIDES:=libmosquitto
endef

define Package/libmosquitto-ssl
    $(call Package/libmosquitto/default)
    TITLE+= (With SSL Support)
    DEPENDS+= +libopenssl
    VARIANT=ssl
endef
define Package/libmosquitto-nossl
    $(call Package/libmosquitto/default)
    TITLE+= (Without SSL Support)
    VARIANT=nossl
endef

define Package/libmosquitto/default/description
 Library required for mosquitto's command line client tools, also for
use by any third party software that wants to communicate with a
mosquitto server.

Should be useable for communicating with any MQTT v3.1/3.1.1 compatible
server, such as IBM's RSMB, in addition to Mosquitto
endef

define Package/libmosquitto-ssl/description
    $(call Package/libmosquitto/default/description)
    This package is built with SSL support
endef
define Package/libmosquitto-nossl/description
    $(call Package/libmosquitto/default/description)
    This package is built without SSL support
endef

define Package/libmosquittopp
    SECTION:=libs
    CATEGORY:=Libraries
    DEPENDS:=libmosquitto +libstdcpp
    TITLE:= mosquitto - client c++ library
endef

define Package/libmosquittopp/description
 C++ Library wrapper for libmosquitto.
endef

define Package/mosquitto-ssl/conffiles
/etc/mosquitto/mosquitto.conf
/etc/config/mosquitto
endef

Package/mosquitto-nossl/conffiles = $(Package/mosquitto-ssl/conffiles)

define Package/mosquitto/install/default
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/mosquitto $(1)/usr/sbin/mosquitto
	$(INSTALL_DIR) $(1)/etc/mosquitto
	$(INSTALL_CONF) $(PKG_BUILD_DIR)/mosquitto.conf $(1)/etc/mosquitto.conf
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/mosquitto.init $(1)/etc/init.d/mosquitto
endef

define Package/mosquitto-nossl/install
	$(call Package/mosquitto/install/default,$(1))
endef

define Package/mosquitto-ssl/install
	$(call Package/mosquitto/install/default,$(1))
ifeq ($(CONFIG_MOSQUITTO_PASSWD),y)
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/mosquitto_passwd $(1)/usr/bin
endif
endef

define Package/mosquitto-client-ssl/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/client/mosquitto_pub $(1)/usr/bin/mosquitto_pub
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/client/mosquitto_sub $(1)/usr/bin/mosquitto_sub
endef
Package/mosquitto-client-nossl/install = $(Package/mosquitto-client-ssl/install)

# This installs files into ./staging_dir/. so that you can cross compile from the host
define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include
	$(CP) $(PKG_BUILD_DIR)/lib/mosquitto.h $(1)/usr/include
	$(CP) $(PKG_BUILD_DIR)/lib/cpp/mosquittopp.h $(1)/usr/include
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_BUILD_DIR)/lib/libmosquitto.so.1 $(1)/usr/lib/
	$(CP) $(PKG_BUILD_DIR)/lib/cpp/libmosquittopp.so.1 $(1)/usr/lib/
	$(LN) libmosquitto.so.1 $(1)/usr/lib/libmosquitto.so
	$(LN) libmosquittopp.so.1 $(1)/usr/lib/libmosquittopp.so
endef

# This installs files on the target.  Compare with Build/InstallDev
define Package/libmosquitto-ssl/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/libmosquitto.so.1 $(1)/usr/lib/
	$(LN) libmosquitto.so.1 $(1)/usr/lib/libmosquitto.so
endef
Package/libmosquitto-nossl/install = $(Package/libmosquitto-ssl/install)

define Package/libmosquittopp/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/cpp/libmosquittopp.so.1 $(1)/usr/lib/
	$(LN) libmosquittopp.so.1 $(1)/usr/lib/libmosquittopp.so
endef

# Applies to all...
MAKE_FLAGS += WITH_DOCS=no UNAME=Linux
ifeq ($(BUILD_VARIANT),nossl)
	MAKE_FLAGS += WITH_TLS=no WITH_WEBSOCKETS=no
else
	MAKE_FLAGS += WITH_WEBSOCKETS=$(if $(CONFIG_MOSQUITTO_LWS),"yes","no")
	MAKE_FLAGS += WITH_TLS_PSK=$(if $(CONFIG_OPENSSL_WITH_PSK),"yes","no")
endif

$(eval $(call BuildPackage,mosquitto-ssl))
$(eval $(call BuildPackage,mosquitto-nossl))
$(eval $(call BuildPackage,libmosquitto-ssl))
$(eval $(call BuildPackage,libmosquitto-nossl))
$(eval $(call BuildPackage,libmosquittopp))
$(eval $(call BuildPackage,mosquitto-client-ssl))
$(eval $(call BuildPackage,mosquitto-client-nossl))
