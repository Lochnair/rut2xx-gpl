include $(TOPDIR)/rules.mk

PKG_NAME:=host-block
PKG_RELEASE:=1
PKG_VERSION:=1

include $(INCLUDE_DIR)/package.mk

define Package/host-block
	SECTION:=base
	CATEGORY:=Base system
	TITLE:=Host Block
	DEPENDS:=+dnsmasq-dhcpv6
endef

define Package/host-block/description
	Host Blocker.
endef

define Package/host-block/conffiles
	/etc/config/hostblock
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/* $(PKG_BUILD_DIR)/
endef

define Build/Compile

endef

define Package/host-block/install
	$(INSTALL_DIR) $(1)/etc/init.d/
	$(INSTALL_DIR) $(1)/etc/config/
	$(INSTALL_DIR) $(1)/usr/sbin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/hostblock.init $(1)/etc/init.d/hostblock
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/hostblock.conf $(1)/etc/config/hostblock
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/hostblock.sh $(1)/usr/sbin/hostblock.sh
endef

$(eval $(call BuildPackage,host-block))
