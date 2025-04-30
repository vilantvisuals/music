import discord
from discord.ext import commands
from discord.ui import Button, View, Modal, TextInput
import requests
import base64

# ========= BOT SETUP =========
intents = discord.Intents.default()
intents.message_content = True
client = commands.Bot(command_prefix="!", intents=intents)
client.remove_command("help")

# ========= GITHUB CONFIG =========
GITHUB_TOKEN = "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"
REPO_OWNER = "vilantvisuals"
REPO_NAME = "wl"
FILE_PATH = "sl"
GITHUB_API_URL = f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/contents/{FILE_PATH}"

# ========= WEBHOOK =========
WEBHOOK_URL = "https://discord.com/api/webhooks/1367202640769061095/Cas8eRpZwbVsgQgy5MgcdBaZbC4ynRKCjFZONqiZ3k6DNYoDQb01LGZZlKTrT2Qs0162"

# ========= FUNCTION TO APPEND TO FILE =========
def append_to_file(hwid: str):
    headers = {
        "Authorization": f"token {GITHUB_TOKEN}",
        "Accept": "application/vnd.github.v3+json"
    }

    res = requests.get(GITHUB_API_URL, headers=headers)
    if res.status_code != 200:
        return False

    json_data = res.json()
    old_content = base64.b64decode(json_data['content']).decode('utf-8')
    sha = json_data['sha']

    updated_content = old_content.strip() + f"\n{hwid}"
    encoded_content = base64.b64encode(updated_content.encode()).decode()

    payload = {
        "message": "Appended HWID submission",
        "content": encoded_content,
        "sha": sha
    }

    update = requests.put(GITHUB_API_URL, headers=headers, json=payload)
    return update.status_code == 200

# ========= FUNCTION TO SEND TO WEBHOOK =========
def send_to_webhook(hwid: str, discord_user: str):
    data = {
        "embeds": [{
            "title": "New HWID Submission",
            "color": 0x00ff00,
            "fields": [
                {"name": "HWID", "value": hwid, "inline": False},
                {"name": "Submitted By", "value": discord_user, "inline": False}
            ]
        }]
    }
    requests.post(WEBHOOK_URL, json=data)

# ========= MODAL FORM =========
class SubmitModal(Modal):
    def __init__(self):
        super().__init__(title="Whitelist Setup")
        self.input_hwid = TextInput(label="Your HWID", placeholder="XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXXXX", required=True)
        self.input_discord = TextInput(label="Your Discord user", placeholder="user not display", required=True)

        self.add_item(self.input_hwid)
        self.add_item(self.input_discord)

    async def on_submit(self, interaction: discord.Interaction):
        await interaction.response.defer(ephemeral=True)

        hwid = self.input_hwid.value.strip()
        discord_user_input = self.input_discord.value.strip()

        # Append only HWID to GitHub
        success = append_to_file(hwid)

        # Send full data to Webhook
        send_to_webhook(hwid, discord_user_input)

        if success:
            await interaction.followup.send("✅ Successfully submitted, - whitelisted -", ephemeral=True)
        else:
            await interaction.followup.send("❌ Unexpected error contact @grap3", ephemeral=True)

# ========= BUTTON VIEW =========
class PanelView(View):
    def __init__(self):
        super().__init__(timeout=None)
        submit_button = Button(label="📝 Submit", style=discord.ButtonStyle.green, custom_id="submit_button")
        submit_button.callback = self.submit_callback
        self.add_item(submit_button)

    async def submit_callback(self, interaction: discord.Interaction):
        await interaction.response.send_modal(SubmitModal())

# ========= ON BOT READY =========
@client.event
async def on_ready():
    print(f"✅ Logged in as {client.user}")

    channel = client.get_channel(1367194647465562263)
    if not channel:
        print("❌ Channel not found. Check if bot has access.")
        return

    client.add_view(PanelView())

    async for message in channel.history(limit=10):
        if message.author == client.user and message.embeds and "Panel" in message.embeds[0].title:
            print("✅ Panel already exists.")
            return

    embed = discord.Embed(
        title="Test | Panel",
        description="Submit anything using the button below. It will be saved in the GitHub file.",
        color=discord.Color.blue()
    )

    await channel.send(embed=embed, view=PanelView())

# ========= RUN THE BOT =========
client.run("MTM2NjQxOTY3MjMxNjI0ODE1Nw.GAmDd0.TJiCpjlmTtml_BwjdPTCiA-o-kmJlLR4jDmbus")
