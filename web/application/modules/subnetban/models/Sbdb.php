
<?php if ( ! defined('BASEPATH')) exit('No direct script access allowed');
/**
 * Game AdminPanel (АдминПанель)
 *
 * @package		Game AdminPanel
 * @author		Nikita Kuznetsov (ET-NiK)
 * @copyright	Copyright (c) 2014, Nikita Kuznetsov (http://hldm.org)
 * @license		http://www.gameap.ru/license.html
 * @link		http://www.gameap.ru
 * @filesource	
 */
 
// ------------------------------------------------------------------------

/**
 * Бан подсетей на GolSource серверах
 * 
 * Модель для работы с базами данных subnetban
 * 
 * Для полноценной работы на игровых серверах требуется плагин
 * Subnetban (бан подсетей) http://aghl.ru/forum/viewtopic.php?f=19&t=282
 *
 * @package		Game AdminPanel
 * @category	Models
 * @author		Nikita Kuznetsov (ET-NiK)
 * @sinse		0.8.10
 */

class Sbdb extends CI_Model {
	
	private $_sbdb_id	= 0;			// Идентификатор sb базы
	private $_sbdb 	= false;		// Объект sb базы данных
	private $_sb_cfg 	= false; 		// Параметры sb базы данных с которой работаем
	private $_bans		= array();		// Баны в sb базе
	
	// ------------------------------------------------------------------------
	
	/**
	 * Выбор базы данных subnetban для дальнейшей работы
	*/
	public function select_db($db_id = false)
	{
		$this->load->library('encrypt');
		
		if (!$db_id) {
			return false;
		}
		
		/* Получение сведений из нашей базы данных */
		$this->db->where('id', $db_id);
		$query 	= $this->db->get('sb_databases');
		
		if ($query->num_rows < 1) {
			return false;
		}
		
		$this->_sb_cfg 	= $query->row_array();
		
		$this->_sb_cfg['password'] = $this->encrypt->decode($this->_sb_cfg['password']);
		
		/* Соединяемся с sb базой данных */
		$this->_sbdb 	= $this->load->database($this->_sb_cfg, true);
		$this->_sbdb_id = $db_id;
		
		return true;
	}
	
	// ------------------------------------------------------------------------
	
	/**
	 * Получение данных базы
	*/
	public function get_sbdb()
	{
		if (!$this->_sbdb OR !$this->_sb_cfg) {
			return false;
		}
		
		return $this->_sb_cfg;
	}
	
	// ------------------------------------------------------------------------
	
	private function _flags_to_bytes($flags = '')
	{
		$result = 0;
		$flags = str_split($flags);
		
		$str = array_flip(str_split('abcdefghijklmnopqrstuvwxyz'));

		foreach ($flags as &$val) {
			$result |= 1 << ($str[$val]);
		}
	
		return $result;
	}
	
	// ------------------------------------------------------------------------
	
	private function _bytes_to_flags($in = 0)
	{
		$result = "";
		$str = str_split('abcdefghijklmnopqrstuvwxyz');
		for ($i = 0; $i < 25; $i++) {
			if ($in & (1 << $i)) {
				$result .= $str[$i];
			}
		}

		return $result;
	}
	
	// ------------------------------------------------------------------------
	
	private function _bytes_to_array($bytes = '')
	{
		$flags = str_split($this->_bytes_to_flags($bytes));
		
		$arr['unknown'] 			= in_array('a', $flags) ? true : false;
		$arr['native_steam'] 		= in_array('b', $flags) ? true : false;
		$arr['steamemu'] 			= in_array('c', $flags) ? true : false;
		$arr['rewemu'] 				= in_array('d', $flags) ? true : false;
		$arr['old_rewemu'] 			= in_array('e', $flags) ? true : false;
		$arr['hltv'] 				= in_array('f', $flags) ? true : false;
		$arr['steamclient2009'] 	= in_array('g', $flags) ? true : false;
		$arr['avsmp'] 				= in_array('h', $flags) ? true : false;
		$arr['rewemu2013'] 			= in_array('j', $flags) ? true : false;
		
		return $arr;
	}
	
	// ------------------------------------------------------------------------
	
	private function _bytes_to_human($bytes)
	{
		$flags = str_split($this->_bytes_to_flags($bytes));
		
		$arr[] 	= in_array('a', $flags) ? 'Unknown' : false;
		$arr[] 	= in_array('b', $flags) ? 'Native Steam' : false;
		$arr[] 	= in_array('c', $flags) ? 'SteamEmu' : false;
		$arr[] 	= in_array('d', $flags) ? 'RevEmu' : false;
		$arr[] 	= in_array('e', $flags) ? 'Old RevEmu' : false;
		$arr[] 	= in_array('f', $flags) ? 'HLTV' : false;
		$arr[] 	= in_array('g', $flags) ? 'SteamClient2009' : false;
		$arr[] 	= in_array('h', $flags) ? 'AVSMP' : false;
		$arr[]  = in_array('j', $flags) ? 'RevEmu 2013' : false;
		
		$arr = array_filter($arr,function($el){ return !empty($el);});
		
		return implode(', ', $arr);
	}
	
	public function table_exists()
	{
		return $this->_sbdb->table_exists($this->_sb_cfg['table_name']);
	}
	
	// ------------------------------------------------------------------------
	
	/**
	 * Получение данных из sb базы
	*/
	public function get_bans()
	{
		$this->load->helper('date');
		
		if (!$this->_sbdb OR !$this->_sb_cfg) {
			return false;
		}

		if ($this->_sbdb->table_exists($this->_sb_cfg['table_name'])) {
			$query 			= $this->_sbdb->get($this->_sb_cfg['table_name']);
			$this->_bans 	= $query->result_array();
		}
		
		if (empty($this->_bans)) {
			return false;
		} else {
			return true;
		}

	}
	
	// ------------------------------------------------------------------------
	
	/**
	 * Преобразование данных бана в понятный человеку вид,
	 * который можно использовать в шаблонах и формах
	 */
	private function _human_ban($ban, $allowed_clients_to_array = false)
	{
		$return_ban['ban_id'] 				= $ban['datetimebanned'];
		$return_ban['startip'] 				= long2ip($ban['startip']);
		$return_ban['endip'] 				= long2ip($ban['endip']);
		$return_ban['datetimebanned'] 		= unix_to_human($ban['datetimebanned'], false, 'ru');
		$return_ban['datetimelastblocked'] 	= unix_to_human($ban['datetimelastblocked'], false, 'ru');
		$return_ban['allowedclients']		= $allowed_clients_to_array
														? $this->_bytes_to_array($ban['allowedclients'])
														: $this->_bytes_to_human($ban['allowedclients']);
		$return_ban['reason']				= $ban['reason'];
		
		return $return_ban;
	}
	
	// ------------------------------------------------------------------------
	
	/**
	 * Получение данных из sb базы
	*/
	public function get_tpl_bans()
	{
		if (empty($this->_bans)) {
			$this->get_bans();
		}
		
		if (empty($this->_bans)) {
			return array();
		}
		
		$i = 0;
		foreach ($this->_bans as &$ban) {
			$return_ban[] = $this->_human_ban($ban);
			$i ++;
		}
		
		return $return_ban;
	}
	
	// ------------------------------------------------------------------------
	
	/**
	 * Получение одного бана из базы
	*/
	public function get_ban($ban_id)
	{
		if (!$this->_sbdb OR !$this->_sb_cfg) {
			return false;
		}
		
		$this->_sbdb->where('datetimebanned', $ban_id);
		
		$query 	= $this->_sbdb->get($this->_sb_cfg['table_name']);
		
		if ($query->num_rows < 1) {
			return false;
		}
		
		return $this->_human_ban($query->row_array(), true);
	}
	
	// ------------------------------------------------------------------------
	
	/**
	 * Добавляет базу данных
	*/
	public function add_db($data)
	{
		$this->load->library('encrypt');
		
		// Чтобы никто не догадался
		$data['password'] = $this->encrypt->encode($data['password']);
		
		return $this->db->insert('sb_databases', $data);
	}
	
	// ------------------------------------------------------------------------
	
	/**
	 * Список всех subnetban баз
	*/
	public function get_db_list()
	{
		$query = $this->db->get('sb_databases');
		return $query->result_array();
	}
	
	// ------------------------------------------------------------------------
	
	/**
	 * Вставляет новую запись в базу данных subnetban
	*/
	public function insert($data)
	{
		if (!$this->_sbdb OR !$this->_sb_cfg) {
			return false;
		}
		
		$this->load->helper('date');
		
		$flags = '';
		$flags .= $data['unknown'] 			? 'a' : '';
		$flags .= $data['native_steam'] 	? 'b' : '';
		$flags .= $data['steamemu'] 		? 'c' : '';
		$flags .= $data['rewemu'] 			? 'd' : '';
		$flags .= $data['old_rewemu'] 		? 'e' : '';
		$flags .= $data['hltv'] 			? 'f' : '';
		$flags .= $data['steamclient2009'] 	? 'g' : '';
		$flags .= $data['avsmp'] 			? 'h' : '';
		$flags .= $data['rewemu2013'] 		? 'j' : '';
		
		$sql_data['startip']		= ip2long($data['startip']);
		$sql_data['endip']			= ip2long($data['endip']);
		$sql_data['reason']			= $data['reason'];
		$sql_data['allowedclients'] = $this->_flags_to_bytes($flags);
		
		$sql_data['datetimebanned']			= now();
		$sql_data['datetimelastblocked']	= now();
		
		return $this->_sbdb->insert($this->_sb_cfg['table_name'], $sql_data);
	}
	
	// ------------------------------------------------------------------------
	
	/**
	 * Обновляет запись в базе данных subnetban
	*/
	public function update($ban_id, $data)
	{
		if (!$this->_sbdb OR !$this->_sb_cfg) {
			return false;
		}
		
		$flags = '';
		$flags .= $data['unknown'] 			? 'a' : '';
		$flags .= $data['native_steam'] 	? 'b' : '';
		$flags .= $data['steamemu'] 		? 'c' : '';
		$flags .= $data['rewemu'] 			? 'd' : '';
		$flags .= $data['old_rewemu'] 		? 'e' : '';
		$flags .= $data['hltv'] 			? 'f' : '';
		$flags .= $data['steamclient2009'] 	? 'g' : '';
		$flags .= $data['avsmp'] 			? 'h' : '';
		$flags .= $data['rewemu2013'] 		? 'j' : '';
		
		$sql_data['startip']		= ip2long($data['startip']);
		$sql_data['endip']			= ip2long($data['endip']);
		$sql_data['reason']			= $data['reason'];
		$sql_data['allowedclients'] = $this->_flags_to_bytes($flags);
		
		$this->_sbdb->where('datetimebanned', $ban_id);
		return $this->_sbdb->update($this->_sb_cfg['table_name'], $sql_data);
	}
	
	// ------------------------------------------------------------------------
	
	/**
	 * Обновляет сведения о базе subnetban
	*/
	public function update_db($data)
	{
		$this->load->library('encrypt');
		
		// Чтобы никто не догадался
		$data['password'] = $this->encrypt->encode($data['password']);
		
		$this->db->where('id', $this->_sbdb_id);
		return $this->db->update('sb_databases', $data);
	}
	
	// ------------------------------------------------------------------------
	
	/**
	 * Удялает запись в базе subnetban
	*/
	public function delete_db()
	{
		if (!$this->_sbdb OR !$this->_sb_cfg) {
			return false;
		}

		$this->db->where('id', $this->_sbdb_id);
		return $this->db->delete('sb_databases');
	}
	
	// ------------------------------------------------------------------------
	
	/**
	 * Удялает запись в базе subnetban
	*/
	public function delete($ban_id)
	{
		if (!$this->_sbdb OR !$this->_sb_cfg) {
			return false;
		}

		$this->_sbdb->where('datetimebanned', $ban_id);
		return $this->_sbdb->delete($this->_sb_cfg['table_name']);
	}
}
