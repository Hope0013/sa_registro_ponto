# Aplicativo de Registro de Ponto com Geolocalização e Biometria

## 1. Escopo
O aplicativo permite que funcionários façam a autenticação por NIF/E-mail e senha ou por biometria (impressão digital ou reconhecimento facial), e só permite bater o ponto se o funcionário estiver a menos de 100 metros do local de trabalho, calculando a distância pelo GPS em tempo real.

---

## 2. Funcionalidades do Aplicativo

1. **Autenticação Flexível:**
   - Login por NIF ou E-mail com senha.
   - Login por Biometria (digital ou reconhecimento facial) com 1 toque.
   - Tela de cadastro de novos funcionários.
   - Botão para preencher automaticamente as credenciais de teste para o professor.

2. **Verificação de Localização (Geolocalização):**
   - O GPS do aparelho obtém as coordenadas exatas de latitude e longitude do funcionário.
   - O aplicativo calcula a distância em linha reta entre a localização do funcionário e o ponto da empresa.
   - Regra dos 100 metros: Se o funcionário estiver a mais de 100 metros, o ponto é bloqueado e é exibido um aviso em vermelho informando a distância atual.
   - Se estiver a até 100 metros, um indicador verde confirma que o ponto está liberado.

3. **Facilitador para Testes do Professor (Ajuste de Local):**
   - Na tela de configurações da empresa, há um botão: Usar minha localização atual como Empresa.
   - Isso permite o teste so aplicativo de qualquer lugar.

4. **Armazenamento Local em Banco SQL (SQLite):**
   - Registra data, horário exato, tipo de batida (Entrada, Intervalo, Retorno, Saída), método de confirmação (Senha ou Biometria), coordenadas GPS e distância calculada.
   - Funciona totalmente offline.

5. **Histórico de Registros:**
   - Lista todas as batidas de ponto anteriores do funcionário logado em ordem cronológica.

---

## 3. Como Rodar o Aplicativo

### Pré-requisitos
- Flutter SDK instalado (versão 3.10 ou superior).
- Um emulador Android configurado ou um aparelho celular conectado via cabo USB com depuração ativada.

### 3.1 Passo a Passo

1. **Baixar as dependências do projeto:**
   Abra o terminal na pasta do projeto e execute:
   ```bash
   flutter pub get
   ```

2. **Executar o aplicativo:**
   No emulador ou celular conectado, rode:
   ```bash
   flutter run
   ```

3. **Credenciais para Teste Rápido:**
   O aplicativo já vem com um usuário padrão cadastrado no banco:
   - **NIF:** `123456`
   - **Senha:** `123456`
   *(Você também pode clicar no botão "Preencher credenciais de teste" na tela de login).*

---

## 4. Estrutura das Pastas

```text
lib/
├── models/                     # Modelos de dados do aplicativo
│   ├── punch_model.dart        # Representa o registro de ponto
│   ├── user_model.dart         # Representa o funcionario
│   └── workplace_model.dart    # Representa as coordenadas da empresa
├── screens/                    # Telas do aplicativo
│   ├── history_screen.dart     # Tela de historico de pontos
│   ├── home_screen.dart        # Tela principal (relogio, GPS e batida de ponto)
│   ├── login_screen.dart       # Tela de login (senha ou biometria)
│   ├── register_screen.dart    # Cadastro de novos colaboradores
│   └── workplace_config_screen.dart # Ajuste das coordenadas da empresa
├── services/                   # Servicos de hardware e banco de dados
│   ├── biometric_service.dart  # Comunicacao com o leitor biometrico nativo
│   ├── database_service.dart   # Banco de dados SQLite local
│   └── location_service.dart   # Servico de GPS e calculo de distancia
├── theme/
│   └── app_theme.dart          # Paleta de cores azul escuro e estilos visuais
└── main.dart                   # Ponto de entrada do app
```

---

## 5. Pacotes Utilizados

- `sqflite` e `path`: Gerenciamento e persistência no banco de dados SQLite local.
- `geolocator`: Acesso ao hardware de GPS do aparelho e cálculo de distâncias entre duas coordenadas.
- `local_auth`: Integração nativa com os sensores biométricos (leitor de digital e reconhecimento facial).
- `intl`: Formatação de datas e horários no padrão brasileiro (`pt_BR`).