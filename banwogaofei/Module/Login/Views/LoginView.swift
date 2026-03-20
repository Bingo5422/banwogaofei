import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject var router: Router

    var body: some View {
        VStack(spacing: 0) {
            VStack {
                Spacer()
                Image("logo-login")
                    .resizable()
                    .frame(width: Screen.adapt(88), height: Screen.adapt(88))
                    .cornerRadius(22)
                    .padding(.top, Screen.adapt(50)) // 使用 padding 稳住位置
                Text("伴我高飞")
                    .font(.system(size: 14))
                    .foregroundColor(.black)
                    .padding(.top, 8)
                Spacer()
            }
            .frame(height: Screen.adapt(260))

            VStack(spacing: Screen.adapt(30)) {
                VStack(alignment: .leading, spacing: Screen.adapt(10)) {
                    Text("手机号")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#666666"))
                    TextField("", text: $viewModel.phoneNumber, prompt:
                                Text("请输入手机号").foregroundColor(.secondary)
                    )
                        .keyboardType(.numberPad)
                        .foregroundColor(.black)
                        .padding()
                        .frame(height: 50)
                        .background(Color(hex: "#FAFAFC"))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .onChange(of: viewModel.phoneNumber) { _ in
                            viewModel.validatePhoneNumber()
                        }
                    if !viewModel.phoneNumber.isEmpty && !viewModel.isPhoneNumberValid {
                        Text("请输入有效的11位手机号")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                VStack(alignment: .leading, spacing: Screen.adapt(10)) {
                    Text("验证码")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#666666"))
                    HStack(spacing: 12) {
                        TextField("", text: $viewModel.verificationCode, prompt: Text("请输入验证码").foregroundColor(.secondary)
                        )
                            .keyboardType(.numberPad)
                            .padding()
                            .foregroundColor(.black)
                            .frame(height: 50)
                            .background(Color(hex: "#FAFAFC"))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        Button(action: { viewModel.sendVerificationCode() }) {
                            Text(viewModel.canSendCode ? "获取验证码" : "\(viewModel.countdown)s")
                                .font(.system(size: 16))
                                .foregroundColor(Color(hex: "#FFA313"))
                                .frame(width: 104, height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color(hex: "#FFA313").opacity(0.18))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14)
                                                .stroke(Color(hex: "#FFA313"), lineWidth: 0.5)
                                        )
                                )
                        }
                        .disabled(!viewModel.canSendCode || viewModel.isCheckingCoach)
                    }
                    
                    if let error = viewModel.coachCheckError {
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundColor(.red) // 使用红色提醒
                            .padding(.horizontal, 5)
                            .transition(.opacity) // 加上简单的过渡动画
                    }
                }

                Button(action: { viewModel.login() }) {
                    Text("登录")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(hex: "#FFA313"))
                        .cornerRadius(14)
                        .contentShape(Rectangle())
                        .shadow(color: Color(hex: "#FFA313").opacity(0.3), radius: 12, x: 1, y: 1)
                }
                .disabled(viewModel.isLoginButtonDisabled)
                .padding(.top, Screen.adapt(10))
            }
            .padding(.horizontal, Screen.adapt(35))

            Spacer()

            VStack(spacing: Screen.adapt(20)) {
                HStack {
                    VStack { Divider().background(Color.gray.opacity(0.2)) }
                    Text("其他方式登录")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#999999"))
                    VStack { Divider().background(Color.gray.opacity(0.2)) }
                }
                // 给微信图标添加点击事件
                Button(action: {
                    viewModel.loginWithWeChat() // 调用 ViewModel 里的新方法
                }){
                    Image("weixin")
                        .resizable()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, Screen.adapt(60))
            
            Spacer()
        }
        .fullScreenBackground(
            Image("shouye-bg")
                .resizable()
                .scaledToFill()
        )
        .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
         }
        .onAppear {
            viewModel.router = router
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(Router())
    }
}
