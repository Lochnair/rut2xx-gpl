include $(TOPDIR)/rules.mk

PKG_NAME:=brand
PKG_VERSION:=1

include $(INCLUDE_DIR)/package.mk


define Package/brand
  SECTION:=base
  CATEGORY:=Base system
  TITLE:=Web branding application
  DEPENDS:=+libbrand
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Package/brand/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/brand $(1)/usr/sbin/brand	
endef

$(eval $(call BuildPackage,brand))