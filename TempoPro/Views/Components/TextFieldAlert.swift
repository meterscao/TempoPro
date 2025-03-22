//
//  TextFieldAlert.swift
//  TempoPro
//
//  Created by Ringo Cao on 2025/3/22.
//


import SwiftUI
import UIKit

struct TextFieldAlert {
    // 警报标题
    let title: String
    // 警报信息
    let message: String?
    // 占位符文本
    let placeholder: String
    // 初始文本
    var text: String = ""
    // 确认按钮文本
    let confirmText: String
    // 取消按钮文本
    let cancelText: String
    // 确认操作
    let onConfirm: (String) -> Void
    // 取消操作
    let onCancel: () -> Void
}

extension View {
    func textFieldAlert(isPresented: Binding<Bool>, alert: TextFieldAlert) -> some View {
        TextFieldAlertWrapper(isPresented: isPresented, alert: alert, content: self)
    }
}

struct TextFieldAlertWrapper<Content: View>: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let alert: TextFieldAlert
    let content: Content
    
    func makeUIViewController(context: Context) -> UIHostingController<Content> {
        let controller = UIHostingController(rootView: content)
        controller.view.backgroundColor = .clear
        return controller
    }
    
    final class Coordinator {
        var alertController: UIAlertController?
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func updateUIViewController(_ uiViewController: UIHostingController<Content>, context: Context) {
         uiViewController.rootView = content
        // 确保背景始终是透明的
        uiViewController.view.backgroundColor = UIColor(Color("backgroundPrimaryColor"))
        if isPresented && context.coordinator.alertController == nil {
            let alertController = UIAlertController(
                title: alert.title,
                message: alert.message,
                preferredStyle: .alert
            )
            
            // 添加文本输入框
            alertController.addTextField { textField in
                textField.placeholder = alert.placeholder
                textField.text = alert.text
            }
            
            // 取消按钮
            alertController.addAction(UIAlertAction(title: alert.cancelText, style: .cancel) { _ in
                isPresented = false
                context.coordinator.alertController = nil
                alert.onCancel()
            })
            
            // 确认按钮
            alertController.addAction(UIAlertAction(title: alert.confirmText, style: .default) { _ in
                if let textField = alertController.textFields?.first, let text = textField.text {
                    alert.onConfirm(text)
                }
                isPresented = false
                context.coordinator.alertController = nil
            })
            
            uiViewController.present(alertController, animated: true)
            context.coordinator.alertController = alertController
        }
        
        // 如果isPresented变为false，关闭警报
        if !isPresented && context.coordinator.alertController != nil {
            context.coordinator.alertController?.dismiss(animated: true)
            context.coordinator.alertController = nil
        }
    }
}
