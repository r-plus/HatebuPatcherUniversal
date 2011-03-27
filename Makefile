include theos/makefiles/common.mk

TWEAK_NAME = HatebuPatcherUniversal
HatebuPatcherUniversal_FILES = Tweak.xm
HatebuPatcherUniversal_FRAMEWORKS = UIKit CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk
