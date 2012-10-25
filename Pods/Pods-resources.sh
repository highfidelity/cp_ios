#!/bin/sh

install_resource()
{
  case $1 in
    *.storyboard)
      echo "ibtool --errors --warnings --notices --output-format human-readable-text --compile ${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename $1 .storyboard`.storyboardc ${PODS_ROOT}/$1 --sdk ${SDKROOT}"
      ibtool --errors --warnings --notices --output-format human-readable-text --compile "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename $1 .storyboard`.storyboardc" "${PODS_ROOT}/$1" --sdk "${SDKROOT}"
      ;;
    *.xib)
      echo "ibtool --errors --warnings --notices --output-format human-readable-text --compile ${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename $1 .xib`.nib ${PODS_ROOT}/$1 --sdk ${SDKROOT}"
      ibtool --errors --warnings --notices --output-format human-readable-text --compile "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/`basename $1 .xib`.nib" "${PODS_ROOT}/$1" --sdk "${SDKROOT}"
      ;;
    *)
      echo "cp -R ${PODS_ROOT}/$1 ${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
      cp -R "${PODS_ROOT}/$1" "${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
      ;;
  esac
}
install_resource 'SVProgressHUD/SVProgressHUD/SVProgressHUD.bundle'
install_resource 'uservoice-iphone-sdk/Resources/en.lproj'
install_resource 'uservoice-iphone-sdk/Resources/fr.lproj'
install_resource 'uservoice-iphone-sdk/Resources/it.lproj'
install_resource 'uservoice-iphone-sdk/Resources/uv_alert.png'
install_resource 'uservoice-iphone-sdk/Resources/uv_alert@2x.png'
install_resource 'uservoice-iphone-sdk/Resources/uv_article.png'
install_resource 'uservoice-iphone-sdk/Resources/uv_article@2x.png'
install_resource 'uservoice-iphone-sdk/Resources/uv_default_avatar.png'
install_resource 'uservoice-iphone-sdk/Resources/uv_default_avatar@2x.png'
install_resource 'uservoice-iphone-sdk/Resources/uv_error_connection.png'
install_resource 'uservoice-iphone-sdk/Resources/uv_error_connection@2x.png'
install_resource 'uservoice-iphone-sdk/Resources/uv_idea.png'
install_resource 'uservoice-iphone-sdk/Resources/uv_idea@2x.png'
install_resource 'uservoice-iphone-sdk/Resources/uv_karma_star.png'
install_resource 'uservoice-iphone-sdk/Resources/uv_karma_star@2x.png'
install_resource 'uservoice-iphone-sdk/Resources/uv_logo.png'
install_resource 'uservoice-iphone-sdk/Resources/uv_logo@2x.png'
install_resource 'uservoice-iphone-sdk/Resources/uv_primary_button_green.png'
install_resource 'uservoice-iphone-sdk/Resources/uv_primary_button_green@2x.png'
install_resource 'uservoice-iphone-sdk/Resources/uv_primary_button_green_active.png'
install_resource 'uservoice-iphone-sdk/Resources/uv_primary_button_green_active@2x.png'
install_resource 'uservoice-iphone-sdk/Resources/uv_primary_button_red.png'
install_resource 'uservoice-iphone-sdk/Resources/uv_primary_button_red@2x.png'
install_resource 'uservoice-iphone-sdk/Resources/uv_primary_button_red_active.png'
install_resource 'uservoice-iphone-sdk/Resources/uv_primary_button_red_active@2x.png'
install_resource 'uservoice-iphone-sdk/Resources/uv_user_chicklet_dark.png'
install_resource 'uservoice-iphone-sdk/Resources/uv_user_chicklet_dark@2x.png'
install_resource 'uservoice-iphone-sdk/Resources/uv_user_chicklet_detail.png'
install_resource 'uservoice-iphone-sdk/Resources/uv_user_chicklet_detail@2x.png'
install_resource 'uservoice-iphone-sdk/Resources/uv_user_chicklet_light.png'
install_resource 'uservoice-iphone-sdk/Resources/uv_user_chicklet_light@2x.png'
install_resource 'uservoice-iphone-sdk/Resources/uv_vote_chicklet.png'
install_resource 'uservoice-iphone-sdk/Resources/uv_vote_chicklet@2x.png'
install_resource 'uservoice-iphone-sdk/Resources/uv_vote_chicklet_empty.png'
install_resource 'uservoice-iphone-sdk/Resources/uv_vote_chicklet_empty@2x.png'
install_resource 'uservoice-iphone-sdk/Resources/zh-Hant.lproj'
