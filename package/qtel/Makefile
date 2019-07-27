include $(TOPDIR)/rules.mk

PKG_NAME:=quectelis
PKG_VERSION:=1
PKG_BUILD_DIR:=$(BUILD_DIR)/quectelis

include $(INCLUDE_DIR)/package.mk

define Package/quectelis
  SECTION:=base
  CATEGORY:=Base system
  TITLE:=SIM switch daemon by Teltonika
#  DEPENDS:=
endef

define Package/quectelis/description
	quectelis by Teltonika
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Configure
endef

define Build/Compile
	$$(MAKE) $(PKG_JOBS) -C $(PKG_BUILD_DIR) \
	$(TARGET_CONFIGURE_OPTS) TEST=$(TEST)
endef



	
define Package/quectelis/install
	$(INSTALL_DIR) $(1)/usr/sbin/
endef

$(eval $(call BuildPackage,quectelis))
