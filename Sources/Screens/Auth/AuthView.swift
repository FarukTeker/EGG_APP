import SwiftUI

// MARK: - UC-02, UC-03, UC-04: Auth Flow

struct AuthFlowView: View {
    @State private var route: AuthRoute = .login

    enum AuthRoute { case login, register, forgotPassword, emailSent, resetPassword }

    var body: some View {
        ZStack {
            Color.bgApp.ignoresSafeArea()
            switch route {
            case .login:         LoginView(goRegister: { route = .register }, goForgot: { route = .forgotPassword })
            case .register:      RegisterView(goLogin: { route = .login })
            case .forgotPassword: ForgotPasswordView(onSent: { route = .emailSent }, onBack: { route = .login })
            case .emailSent:     EmailSentView(onBack: { route = .login })
            case .resetPassword: ResetPasswordView(onDone: { route = .login })
            }
        }
    }
}

// MARK: - Login Screen (UC-03)

struct LoginView: View {
    @EnvironmentObject private var store: AppStore
    @State private var email = ""
    @State private var password = ""
    @State private var errorText: String? = nil

    var goRegister: () -> Void
    var goForgot: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Avatar — large filled accent circle with a white person glyph (Figma "Sign in")
                Circle()
                    .fill(Color.brandYellow)
                    .frame(width: 96, height: 96)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.white)
                    )
                    .padding(.top, 72)
                    .padding(.bottom, 48)

                VStack(spacing: 12) {
                    VInput(placeholder: "e-mail", text: $email)
                    VInput(placeholder: "Password", text: $password, isSecure: true)

                    // Forgot-password link sits directly under the password field, right-aligned
                    HStack {
                        Spacer()
                        VLinkBtn(title: "Forgot your password?") { goForgot() }
                    }
                }
                .padding(.horizontal, 24)

                if let err = errorText {
                    Text(err)
                        .font(.vestelCaption)
                        .foregroundStyle(Color.brandYellow)
                        .padding(.top, 8)
                }

                VStack(spacing: 12) {
                    VBtn(title: "Log In") {
                        if !store.login(email: email, password: password) {
                            errorText = "Invalid email or password."
                        }
                    }
                    VBtn(title: "Register", kind: .secondary) { goRegister() }
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity)  // ScrollView içindeki VStack genişliği için gerekli
        }
    }
}

// MARK: - Register Screen (UC-02)

struct RegisterView: View {
    @EnvironmentObject private var store: AppStore
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var repeatPassword = ""
    @State private var errorText: String? = nil

    var goLogin: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text("Register")
                    .font(.vestelH2)
                    .foregroundStyle(Color.fg1)
                    .padding(.top, 60)
                    .padding(.bottom, 32)

                VStack(spacing: 12) {
                    VInput(placeholder: "Name",            text: $firstName)
                    VInput(placeholder: "Last Name",        text: $lastName)
                    VInput(placeholder: "example@email.com", text: $email)
                    VInput(placeholder: "Password",         text: $password,       isSecure: true)
                    VInput(placeholder: "Repeat Password",  text: $repeatPassword, isSecure: true)
                }
                .padding(.horizontal, 24)

                if let err = errorText {
                    Text(err)
                        .font(.vestelCaption)
                        .foregroundStyle(Color.brandYellow)
                        .padding(.top, 8)
                }

                VStack(spacing: 12) {
                    VBtn(title: "Continue") {
                        if password != repeatPassword {
                            errorText = "Passwords do not match."
                            return
                        }
                        if password.count < 8 {
                            errorText = "Password must be at least 8 characters."
                            return
                        }
                        if !store.register(firstName: firstName, lastName: lastName, email: email, password: password) {
                            errorText = "Registration failed. Please try again."
                        }
                    }
                    VLinkBtn(title: "Already have an account? Log in") { goLogin() }
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Forgot Password Screen (UC-04)

struct ForgotPasswordView: View {
    @State private var email = ""
    var onSent: () -> Void
    var onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { onBack() } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(Color.fg1)
                    .frame(width: 32, height: 32)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            Text("Reset password")
                .font(.vestelH2)
                .foregroundStyle(Color.fg1)
                .padding(.horizontal, 24)
                .padding(.top, 20)

            Text("Enter your email and we'll send a link to set a new password.")
                .font(.vestelCaption)
                .foregroundStyle(Color.fg2)
                .lineSpacing(4)
                .padding(.horizontal, 24)
                .padding(.top, 8)

            VInput(placeholder: "example@email.com", text: $email)
                .padding(.horizontal, 24)
                .padding(.top, 24)

            Spacer()

            VStack(spacing: 12) {
                VBtn(title: "Send reset link") { onSent() }
                VLinkBtn(title: "Back to log in") { onBack() }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color.bgApp.ignoresSafeArea())
    }
}

// MARK: - Email Sent Screen (UC-04)

struct EmailSentView: View {
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VTopbar(showAvatar: false)
            Spacer()
            VBigIcon(systemName: "checkmark", tone: .success)
            Text("Check your inbox")
                .font(.vestelH2)
                .foregroundStyle(Color.fg1)
                .padding(.top, 16)
            Group {
                Text("We sent a reset link to ") +
                Text("ahmet@vestel.com").bold() +
                Text(". The link expires in 30 minutes.")
            }
            .font(.vestelCaption)
            .foregroundStyle(Color.fg2)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
            .padding(.top, 10)
            Spacer()
            VStack(spacing: 12) {
                VBtn(title: "Open mail app") { }
                VBtn(title: "Resend", kind: .ghost) { }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color.bgApp.ignoresSafeArea())
    }
}

// MARK: - Reset Password Screen (UC-04)

struct ResetPasswordView: View {
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    var onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button { onDone() } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(Color.fg1)
                    .frame(width: 32, height: 32)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            Text("Set new password")
                .font(.vestelH2)
                .foregroundStyle(Color.fg1)
                .padding(.horizontal, 24)
                .padding(.top, 20)

            VStack(spacing: 12) {
                VInput(placeholder: "New password",          text: $newPassword,    isSecure: true)
                VInput(placeholder: "Confirm new password",  text: $confirmPassword, isSecure: true)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            Text("8+ characters, at least one number.")
                .font(.vestelCaption)
                .foregroundStyle(Color.fg3)
                .padding(.horizontal, 24)
                .padding(.top, 10)

            Spacer()

            VBtn(title: "Update password") { onDone() }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
        }
        .background(Color.bgApp.ignoresSafeArea())
    }
}
