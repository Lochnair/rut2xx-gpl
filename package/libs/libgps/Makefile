#
# Copyright (C) 2015 Teltonika
#

include $(TOPDIR)/rules.mk

PKG_NAME:=libgps
PKG_VERSION:=1.0
PKG_RELEASE:=1

include $(INCLUDE_DIR)/package.mk

define Package/libgps
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=A library for manage gps API.
   DEPENDS:=+libusb-1.0 +libgsm +libeventslog
endef

define Package/libgps/description
  A simple lib with at commands to manage gps.
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

TARGET_CFLAGS += $(FPIC)

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) \
		$(TARGET_CONFIGURE_OPTS) \
		CFLAGS="$(TARGET_CFLAGS)" \
		all
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_DIR) $(1)/usr/include/libgps
	$(CP) $(PKG_BUILD_DIR)/include/* $(1)/usr/include/libgps
	$(CP) $(PKG_BUILD_DIR)/libgps.so $(1)/usr/lib/
endef

define Package/libgps/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(CP) $(PKG_BUILD_DIR)/libgps.so $(1)/usr/lib/
endef

$(eval $(call BuildPackage,libgps))
